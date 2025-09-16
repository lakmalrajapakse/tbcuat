@isTest
public with sharing class SIM_MassUnDeleteBatch_test {    

    static void createTestData(){
        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        invoiceTermsList[0].TimesheetsOnInvoices__c = InvoiceTerm__c.TimesheetsOnInvoices__c.getDescribe().getPicklistValues().get(0).getValue();
        insert invoiceTermsList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
        insert picklistLibrariesList;

        // Create Account 
        List<Account> accountsList = TestDataCreator.createClients(
            2, 
            invoiceTermsList[0].Id,
            picklistLibrariesList[0].Id
        );
        insert accountsList;        
    }

    @IsTest
    static void test_Batch(){
        createTestData();
        
        List<Account> accounts = [SELECT Id FROM Account];        
        Id toDeleteId = accounts[0].Id;
        system.assertEquals(2, accounts.size());
        delete accounts[0];

        Test.startTest();
        Database.executeBatch(new SIM_MassUnDeleteBatch('Account', 'Id = \'' + toDeleteId + '\''));
        Test.stopTest();

        List<Account> leftovers = [SELECT Id FROM Account];
        system.assertEquals(2, leftovers.size());        
    }
}