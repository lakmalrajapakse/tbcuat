@IsTest
public with sharing class SIM_LookupAuraService_Test {
    
    static Contact candidate;
    static Contact clientContact;
    static Account clientAccount;

    static void createTestData() {

        // Create test account
       

        clientAccount = new Account(Name='Test Account Name');
        clientAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
       
        insert clientAccount;

        // Create test contacts
        Id contactRT = Schema.SObjectType.contact.getRecordTypeInfosByDeveloperName().get('Candidate').getRecordTypeId();
        candidate = new Contact(email='tet324155@fja3sf4ds.com',FirstName = 'Ridge', LastName = 'Tito', RecordTypeId = contactRT, AccountId = clientAccount.Id);
        clientContact = new Contact(email='tet3299975@fja3da4ds.com',FirstName = 'Ridge2', LastName = 'Tito', RecordTypeId = contactRT, AccountId = clientAccount.Id);

        insert new List<Contact> {candidate, clientContact};

    }

    @IsTest
    static void testGetOneRecordById() {
        createTestData();

        SIM_LookupAuraService.Searchable searcher = new SIM_LookupAuraService.Searchable();
        searcher.searchTerm = 'Customer';
        searcher.objectName = 'Account';
        searcher.fields = new List<String> { 'Name', 'Id' };

        Test.startTest();
        String responseJSON = SIM_LookupAuraService.getOneRecordById(clientAccount.Id, JSON.serialize(searcher));
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseJSON);
        Test.stopTest();

        System.assertEquals(true, (Boolean)response.get('success'));
        List<Object> queried = (List<Object>)response.get('responseObject');
        System.assertEquals(1, queried.size());
    }

    @IsTest
    static void testGetRecent() {
        createTestData();

        SIM_LookupAuraService.Searchable searcher = new SIM_LookupAuraService.Searchable();
        searcher.searchTerm = 'Customer';
        searcher.objectName = 'Account';
        searcher.fields = new List<String> { 'Name', 'Id' };

        Test.startTest();
        String responseJSON = SIM_LookupAuraService.getRecent(JSON.serialize(searcher));
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseJSON);
        Test.stopTest();

        System.assertEquals(true, (Boolean)response.get('success'));
        List<Object> queried = (List<Object>)response.get('responseObject');
    }

    @IsTest
    static void testGetRecords() {
        createTestData();

        SIM_LookupAuraService.Searchable searcher = new SIM_LookupAuraService.Searchable();
        searcher.searchTerm = 'Client Account';
        searcher.objectName = 'Account';
        searcher.fields = new List<String> { 'Name', 'Id' };

        Test.startTest();
        String responseJSON = SIM_LookupAuraService.getRecords(JSON.serialize(searcher));
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseJSON);
        Test.stopTest();

        System.assertEquals(true, (Boolean)response.get('success'));
        List<Object> queried = (List<Object>)response.get('responseObject');
        System.assertNotEquals(0, queried.size());  // Ensure some records are returned
    }
}