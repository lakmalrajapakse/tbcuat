public with sharing class DAVIS_CheckDrivingLicenseInvoker {
    @AuraEnabled
    public static void checkDriver(Contact cont) {
        try {

            cont = [
                SELECT Id, Davis_Id__c, FirstName, LastName, Davis_Status__c, Next_Check_Date__c
                FROM Contact 
                WHERE Id = :cont.Id
                LIMIT 1
            ];

            if (String.isBlank(cont.Davis_Id__c)) {
                throw new AuraHandledException('Davis_Id__c is missing for this contact.');
            }

            List<sirenum__Ticket__c> existingTickets = [
                SELECT Id,Name, Offence_Date__c,sirenum__TicketType__r.Name, sirenum__TicketType__r.Offence_Code__c,sirenum__Owner__c,Commenced_date__c,sirenum__Valid_from__c
                FROM sirenum__Ticket__c 
                WHERE sirenum__Owner__c =: cont.Id
            ];


            DavisManager dm = new DavisManager();
            DavisManager.DriverWrapper driver = dm.checkDrivingLicense(cont, true,existingTickets);

            if (driver != null) {
                // Upsert Contact if updated
                if (driver.driverContact != null) {
                    update driver.driverContact;
                }

                if (!driver.tickets.isEmpty()) {
                    system.debug('driver tickets: '+driver.tickets);
                    Database.SaveResult[] ticketResults = Database.insert(driver.tickets, false);
                    Davis_Error_Log__c errorLog;
                    List<Davis_Error_Log__c> errorLogs= new List<Davis_Error_Log__c>();
                    for (Integer i = 0; i < ticketResults.size(); i++) {
                        if (!ticketResults[i].isSuccess()) {
                            System.debug('Ticket insert failed for: ' + JSON.serialize(driver.tickets[i]) +
                                         ' - Error: ' + ticketResults[i].getErrors()[0].getMessage());
                            errorLog = dm.createErrorLog(driver.tickets[i].sirenum__Owner__c,ticketResults[i].getErrors()[0].getMessage(),driver.tickets[i].sirenum__Comments__c);
                            errorLogs.add(errorLog);
                        }
                    }
                    if(!errorLogs.isEmpty()){
                        insert errorLogs;
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error while checking license: ' + e.getMessage());
        }
    }

    

}