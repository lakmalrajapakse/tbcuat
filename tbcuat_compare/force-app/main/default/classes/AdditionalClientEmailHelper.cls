public without sharing class AdditionalClientEmailHelper {
    public static void manageInvoiceEmailChange(List<SObject> newAdditionalClientEmails,
                                                 Map<Id, SObject> oldAdditionalClientEmailMap) {
        Set<Id> clientIds = new Set<Id>();

        for (SObject obj : newAdditionalClientEmails) {
            Additional_Client_Email__c additionalClientEmail = (Additional_Client_Email__c)obj;
            if (additionalClientEmail.Type__c == 'Invoice'
                || (oldAdditionalClientEmailMap != null && oldAdditionalClientEmailMap.containsKey(additionalClientEmail.Id)
                    && ((Additional_Client_Email__c) oldAdditionalClientEmailMap.get(additionalClientEmail.Id)).Type__c == 'Invoice')) {
                clientIds.add(additionalClientEmail.Client__c);
                if (oldAdditionalClientEmailMap != null && oldAdditionalClientEmailMap.containsKey(additionalClientEmail.Id)) {
                    clientIds.add(((Additional_Client_Email__c) oldAdditionalClientEmailMap.get(additionalClientEmail.Id)).Client__c);
                }
            }         
        }

        if (clientIds.isEmpty()) {
            return;
        }        

        processAdditionalEmails(clientIds);
    }

    private static void processAdditionalEmails(Set<Id> clientIds) {
       List<Account> clients = [select id, Invoicing_Emails__c,  Invoicing_Emails2__c, 
                                         (Select Email__c from Additional_Client_Emails__r where Type__c = 'Invoice' )
                                         from Account where Id in :clientIds];

        List<Account> clientsToUpdate = new List<Account>();

        for (Account client : clients) {
            Set<String> emailSet = new Set<String>();

            for (Additional_Client_Email__c additionalClientEmail : client.Additional_Client_Emails__r) {
                emailSet.add(additionalClientEmail.Email__c);                
            }
            
            String email1;
            String email2;

            for (String email : emailSet) {
                if (email1 == null) {
                    email1 = email;
                    continue;
                }

                if ((email1 + ';' + email).length() <= 255) {
                    email1 = email1 + ';' + email;
                    continue;
                }                

                if (email2 == null) {
                    email2 = email;
                    continue;
                }

                if ((email2 + ';' + email).length() > 255) {
                    break;
                }

                email2 = email2 + ';' + email;
            }

            if (client.Invoicing_Emails__c != email1 || client.Invoicing_Emails2__c != email2) {
               client.Invoicing_Emails__c = email1;
               client.Invoicing_Emails2__c = email2;
               clientsToUpdate.add(client);
            }
        }   

        if (!clientsToUpdate.isEmpty()) {
            update clientsToUpdate;            
        }
        
    }
}