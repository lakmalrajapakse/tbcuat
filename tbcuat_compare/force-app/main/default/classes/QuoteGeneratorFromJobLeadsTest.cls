@isTest
private class QuoteGeneratorFromJobLeadsTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact1', Email = 'test1@example.com', AccountId = acc.Id),
            new Contact(FirstName = 'Test', LastName = 'Contact2', Email = 'test2@example.com', AccountId = acc.Id)
        };
        insert contacts;

        // Create Job Leads (2 for each contact)
        List<TR1__Job_Leads__c> jobLeads = new List<TR1__Job_Leads__c>();
        for (Contact c : contacts) {
            jobLeads.add(new TR1__Job_Leads__c(
                TR1__Contact__c = c.Id,
                TR1__Account__c = acc.Id,
                TR1__Job__c = 'JL-' + c.LastName + '-1',
                TR1__Type__c = 'Permanent',
                Bill_Rate__c = 55
            ));
            jobLeads.add(new TR1__Job_Leads__c(
                TR1__Contact__c = c.Id,
                TR1__Account__c = acc.Id,
                TR1__Job__c = 'JL-' + c.LastName + '-2',
                TR1__Type__c = 'Permanent',
                Bill_Rate__c = 45
            ));
        }
        insert jobLeads;

    
    }

    @isTest
    static void testGenerateQuotes() {
        

       

        // Get job lead IDs
        List<TR1__Job_Leads__c> jobLeads = [
            SELECT Id FROM TR1__Job_Leads__c LIMIT 10
        ];

        List<Id> listIds = new List<Id>();
        listIds.add(jobLeads[0].Id);
        listIds.add(jobLeads[1].Id);



        Test.startTest();
        QuoteGeneratorFromJobLeads.generateQuotes(new List<List<Id>>{
          listIds
        });
        Test.stopTest();

        // Assert Quote created
        Quote__c quote = [SELECT Id, Name FROM Quote__c LIMIT 1];
        System.assertNotEquals(null, quote);

        // Assert Quote_Contacts created
        List<Quote_Contact__c> qcs = [SELECT Id, Person__c, QuoteId__c FROM Quote_Contact__c WHERE QuoteId__c = :quote.Id];
        System.assert(!qcs.isEmpty(), 'Quote contacts should be created');

        // Assert Quote_Contact_Job_Leads created
        List<Quote_Contact_Job_Lead__c> qcjls = [
            SELECT Id, Quote_Contact__c, Job_Lead__c
            FROM Quote_Contact_Job_Lead__c
            WHERE Quote_Contact__c IN :qcs
        ];
        System.assert(!qcjls.isEmpty(), 'Quote contact job leads should be created');
    }
}