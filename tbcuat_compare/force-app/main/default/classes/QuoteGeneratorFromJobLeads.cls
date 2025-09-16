public with sharing class QuoteGeneratorFromJobLeads {

    @InvocableMethod(label='Create Quote and Send Emails')
    public static void generateQuotes(List<List<String>> jobLeadIds) {
        if (jobLeadIds == null || jobLeadIds.isEmpty() || jobLeadIds[0].isEmpty()) return;

        // Step 1: Query Job Leads
        List<TR1__Job_Leads__c> jobLeads = [
            SELECT Id, Name, TR1__Contact__c, TR1__Account__c, TR1__Type__c,Bill_Rate__c,TR1__Job__c,
                   TR1__Contact__r.Email
            FROM TR1__Job_Leads__c
            WHERE Id IN :jobLeadIds[0]
            AND TR1__Contact__c != null
        ];

        if (jobLeads.isEmpty()) return;

        // Step 2: Create Quote__c
        Quote__c quote = new Quote__c(
            Name = 'Quote - ' + DateTime.now().format(),
            Client__c = jobLeads[0].TR1__Account__c
        );
        insert quote;

        // Step 3: Group job leads by contact
        Map<Id, List<TR1__Job_Leads__c>> contactToLeads = new Map<Id, List<TR1__Job_Leads__c>>();
        for (TR1__Job_Leads__c jl : jobLeads) {
            if (!contactToLeads.containsKey(jl.TR1__Contact__c)) {
                contactToLeads.put(jl.TR1__Contact__c, new List<TR1__Job_Leads__c>());
            }
            contactToLeads.get(jl.TR1__Contact__c).add(jl);
        }

        // Step 4: Create Quote_Contact__c records
        List<Quote_Contact__c> quoteContactsToInsert = new List<Quote_Contact__c>();
        Map<Id, Quote_Contact__c> contactIdToQuoteContact = new Map<Id, Quote_Contact__c>();

        for (Id contactId : contactToLeads.keySet()) {
            Quote_Contact__c qc = new Quote_Contact__c(
                Person__c = contactId,
                QuoteId__c = quote.Id
            );
            quoteContactsToInsert.add(qc);
        }
        insert quoteContactsToInsert;
        system.debug('quoteContactsToInsert: '+quoteContactsToInsert);

        for (Quote_Contact__c qc : quoteContactsToInsert) {
            contactIdToQuoteContact.put(qc.Person__c, qc);
        }

        // Step 5: Create Quote_Contact_Job_Lead__c records
        List<Quote_Contact_Job_Lead__c> qcjlsToInsert = new List<Quote_Contact_Job_Lead__c>();

        for (Id contactId : contactToLeads.keySet()) {
            Quote_Contact__c qc = contactIdToQuoteContact.get(contactId);
            for (TR1__Job_Leads__c jl : contactToLeads.get(contactId)) {
                qcjlsToInsert.add(new Quote_Contact_Job_Lead__c(
                    Quote_Contact__c = qc.Id,
                    Job_Lead__c = jl.Id
                ));
            }
        }
        insert qcjlsToInsert;
        system.debug('qcjlsToInsert: '+qcjlsToInsert);

        EmailTemplate template=[SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Quote_email_template' LIMIT 1];
        system.debug('contactToLeads: '+contactToLeads);
        // Step 6: Send VF email to each contact
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Id contactId : contactIdToQuoteContact.keySet()) {
            TR1__Job_Leads__c sampleLead = contactToLeads.get(contactId)[0];
            if (sampleLead.TR1__Contact__r.Email != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(contactId); // sets To address and allows merge fields
                email.setWhatId(contactIdToQuoteContact.get(contactId).Id);          // sets relatedTo (Quote__c)
                email.setTemplateId(template.Id);
                email.setSaveAsActivity(true);
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            system.debug('about to send emails: '+emails);
            Messaging.sendEmail(emails);
        }


        for (TR1__Job_Leads__c jl : jobLeads) {
            jl.Quote_Sent__c = true;
            
        }

        update jobLeads;
    }
}