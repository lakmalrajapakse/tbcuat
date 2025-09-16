public class DAVIS_CheckDrivingLicenseBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Query to fetch the records to process
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Davis_Id__c, Next_Check_Date__c, Disqualified__c, FirstName, 
                   OwnerId, Plan_Code__c
            FROM Contact 
            WHERE Davis_Id__c != null 
              AND (Davis_Status__c = 'Active' OR Davis_Status__c = 'Consent Requested')
              AND (Next_Check_Date__c < TODAY OR Next_Check_Date__c = NULL)
        ]);
    }

    public void execute(Database.BatchableContext context, List<Contact> scope) {

        DavisManager dm = new DavisManager();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<sirenum__Ticket__c> ticketsToInsert = new List<sirenum__Ticket__c>();
        Set<Id> contactIds = new Set<Id>();
        List<Davis_Error_Log__c> errorLogs = new List<Davis_Error_Log__c>();

        for(Contact con:scope){
            contactIds.add(con.Id);    
        }

        List<sirenum__Ticket__c> existingTickets = [
            SELECT Id,Name, Offence_Date__c,sirenum__TicketType__r.Name, sirenum__TicketType__r.Offence_Code__c,sirenum__Owner__c,Commenced_date__c,sirenum__Valid_from__c
            FROM sirenum__Ticket__c 
            WHERE sirenum__Owner__c IN:contactIds
        ];

        system.debug('existingtickets in batch: '+existingTickets);

        Map<Id, List<sirenum__Ticket__c>> existingTicketsByContact = new Map<Id, List<sirenum__Ticket__c>>();
                
        for (sirenum__Ticket__c ticket : existingTickets) {
            Id contactId = ticket.sirenum__Owner__c;
            if (!existingTicketsByContact.containsKey(contactId)) {
                existingTicketsByContact.put(contactId, new List<sirenum__Ticket__c>());
            }
            existingTicketsByContact.get(contactId).add(ticket);
        }

        system.debug('existingTicketsByContact: '+existingTicketsByContact);


        for (Contact contact : scope) {
            try {
                DavisManager.DriverWrapper result = dm.checkDrivingLicense(contact, false,existingTicketsByContact.get(contact.Id));
                if (result != null) {
                    
                    if(result.errorLog!=null){
                        errorLogs.add(result.errorLog);
                        continue;
                    }

                    if (result.driverContact != null) {
                        contactsToUpdate.add(result.driverContact);
                    }
                    if (!result.tickets.isEmpty()) {
                        ticketsToInsert.addAll(result.tickets);
                    }
                }
            } catch (Exception e) {
                System.debug('Error processing contact ' + contact.Id + ': ' + e.getMessage());
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] contactResults = Database.update(contactsToUpdate, false);
            for (Integer i = 0; i < contactResults.size(); i++) {
                if (!contactResults[i].isSuccess()) {                    
                    errorLogs.add(dm.createErrorLog(contactsToUpdate[i].id,contactResults[i].getErrors()[0].getMessage(), ''));
                }
            }
        }

        if (!ticketsToInsert.isEmpty()) {
            Database.SaveResult[] ticketResults = Database.insert(ticketsToInsert, false);

            for (Integer i = 0; i < ticketResults.size(); i++) {
                if (!ticketResults[i].isSuccess()) {
                    System.debug('Ticket insert failed for: ' + JSON.serialize(ticketsToInsert[i]) +
                                 ' - Error: ' + ticketResults[i].getErrors()[0].getMessage());
                    errorLogs.add(dm.createErrorLog(ticketsToInsert[i].sirenum__Owner__c,ticketResults[i].getErrors()[0].getMessage(), ticketsToInsert[i].sirenum__Comments__c));
                }
            }
        }

        if(!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch execution finished.');
    }
}