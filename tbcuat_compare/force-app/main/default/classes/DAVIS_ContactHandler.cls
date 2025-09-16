public class DAVIS_ContactHandler {


    public static void SendDriverDetails(List<contact> drivers){

        System.enqueueJob(new DAVIS_ContactHandler.SendDriverDetailsQueueableBulk(drivers)); //execute a queueable with limit defined in custom setting then chained
    }

    public static void DisableDrivers(List<contact> drivers){

        System.enqueueJob(new DAVIS_ContactHandler.DeleteDriverQueueableBulk(drivers)); //execute a queueable with limit defined in custom setting then chained
    }
    
    public class SendDriverDetailsQueueableBulk implements Queueable, Database.AllowsCallouts {
        private List<Contact> listContacts;
        private Integer processingLimit;
     
        public SendDriverDetailsQueueableBulk(List<Contact> listContacts) {
            this.listContacts = listContacts;
    
            // Fetch processing limit from settings
            Davis_Integration_Settings__c integrationSettings = Davis_Integration_Settings__c.getInstance();
            this.processingLimit = integrationSettings.Max_Contacts_Per_Run__c != null 
                                   ? (Integer) integrationSettings.Max_Contacts_Per_Run__c 
                                   : 10;
        }
    
        public void execute(QueueableContext context) {
            try {
    
                DavisManager dm = new DavisManager();
                List<Contact> contactsToUpdate = new List<Contact>();
                List<sirenum__Ticket__c> ticketsToInsert = new List<sirenum__Ticket__c>();
                List<Davis_Error_Log__c> errorLogs = new List<Davis_Error_Log__c>();
    
                List<Contact> contactsToProcess = new List<Contact>();
                Set<Id> planIds = new Set<Id>();
                List<Contact> remainingContacts = new List<Contact>();
    
                for (Integer i = 0; i < listContacts.size(); i++) {
                    if (i < processingLimit) {
                        contactsToProcess.add(listContacts[i]);
                        planIds.add(listContacts[i].Plan_Code__c);
                    } else {
                        remainingContacts.add(listContacts[i]);
                    }
                }
                    
                // Fetch Picklist Library to get DepartmentId & LocationId
                Map<Id,Picklist_Library__c> mapPicklist = new Map<Id,Picklist_Library__c> ([
                    SELECT Id, Davis_Deparment_Id__c, Branch__r.Davis_Location_Id__c  
                    FROM Picklist_Library__c 
                    WHERE Id IN: planIds
                ]);

                /*List<sirenum__Ticket__c> tickets = [
                    SELECT Id, sirenum__Owner__c, sirenum__TicketType__r.external_Id__c
                    FROM sirenum__Ticket__c 
                    WHERE sirenum__TicketType__r.Competency_Category__c = 'Driver Type'
                    AND sirenum__Owner__c IN :contactsToProcess
                    AND sirenum__Valid__c = TRUE
                ];
                
                Map<Id, List<sirenum__Ticket__c>> driverTypeTicketsByContact = new Map<Id, List<sirenum__Ticket__c>>();
                
                for (sirenum__Ticket__c ticket : tickets) {
                    Id contactId = ticket.sirenum__Owner__c;
                    if (!driverTypeTicketsByContact.containsKey(contactId)) {
                        driverTypeTicketsByContact.put(contactId, new List<sirenum__Ticket__c>());
                    }
                    driverTypeTicketsByContact.get(contactId).add(ticket);
                }
                
                system.debug('tickets: '+tickets);
                system.debug('driverTypeTicketsByContact: '+driverTypeTicketsByContact);
                */
                
                for (Contact con : contactsToProcess) {
                    try {
                     
                        DavisManager.DriverWrapper result = dm.SendDriverDetails(con,
                                                                                 //driverTypeTicketsByContact.get(con.Id),
                                                                                 mapPicklist.get(con.Plan_Code__c));
                        if (result != null) {

                            if(result.errorLog!=null){
                                system.debug('error:'+result.errorLog);
                                errorLogs.add(result.errorLog);
                                continue;
                            }
                            system.debug('result: '+result);
                            if (result.driverContact != null) {
                                system.debug('result: '+result.driverContact);
                                contactsToUpdate.add(result.driverContact);
                            }
                            if (!result.tickets.isEmpty()) {
                                ticketsToInsert.addAll(result.tickets);
                            }
                        }


                    } catch (Exception e) {
                        System.debug('Error sending driver details for contact ' + con.Id + ': ' + e.getMessage());
                    }
                }
                system.debug('about to update: '+contactsToUpdate);
                if (!contactsToUpdate.isEmpty()) {
                    update contactsToUpdate;
                }
                if (!ticketsToInsert.isEmpty()) {
                    insert ticketsToInsert;
                }

                if(!errorLogs.isEmpty()){
                    insert errorLogs;
                }
    
                if (!remainingContacts.isEmpty()) {
                    System.enqueueJob(new SendDriverDetailsQueueableBulk(remainingContacts));
                }
    
            } catch (Exception e) {
                System.debug('Exception in SendDriverDetailsQueueableBulk: ' + e.getMessage());
            }
        }
    }
    
    
    public class DeleteDriverQueueableBulk implements Queueable, Database.AllowsCallouts {
        private List<Contact> contactList;
    
        public DeleteDriverQueueableBulk(List<Contact> contactList) {
            this.contactList = contactList;
        }
    
        public void execute(QueueableContext context) {
            try {
                if (contactList.isEmpty()) return;
    
                Davis_Integration_Settings__c integrationSettings = Davis_Integration_Settings__c.getInstance();
                List<Davis_Error_Log__c> errorLogs = new List<Davis_Error_Log__c>();
    
                Integer maxContacts = integrationSettings.Max_Contacts_Per_Run__c != null 
                                      ? (Integer) integrationSettings.Max_Contacts_Per_Run__c 
                                      : 10;
    
                List<Contact> batchToProcess = new List<Contact>();
                List<Contact> remainingContacts = new List<Contact>();
    
                for (Integer i = 0; i < contactList.size(); i++) {
                    if (i < maxContacts) {
                        batchToProcess.add(contactList[i]);
                    } else {
                        remainingContacts.add(contactList[i]);
                    }
                }
    
                // Initialize DavisManager with settings
                DavisManager dm = new DavisManager();
                List<Contact> contactsToUpdate = new List<Contact>();
    
                for (Contact contact : batchToProcess) {
                    try {
                        DavisManager.DriverWrapper result = dm.deleteDriver(contact);
                        
                        if(result.errorLog!=null){
                            errorLogs.add(result.errorLog);
                            continue;
                        }

                        if (result.driverContact != null) {
                            contactsToUpdate.add(result.driverContact);
                        }

                    } catch (Exception e) {
                        System.debug('Error processing contact: ' + contact.Id + ' - ' + e.getMessage());
                    }
                }
    
                if (!contactsToUpdate.isEmpty()) {
                    update contactsToUpdate;
                }
    
                if (!remainingContacts.isEmpty()) {
                    System.enqueueJob(new DeleteDriverQueueableBulk(remainingContacts));
                }

                if(!errorLogs.isEmpty()){
                    insert errorLogs;
                }
    
            } catch (Exception e) {
                System.debug('Exception in DeleteDriverQueueableBulk: ' + e.getMessage());
            }
        }
    }
    
    

   
}