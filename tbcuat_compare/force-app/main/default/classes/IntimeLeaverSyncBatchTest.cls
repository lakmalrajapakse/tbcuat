/**
*   @description Test class for IntimeLeaverSyncBatch
**/
@isTest(seeAllData=false)
private with sharing class IntimeLeaverSyncBatchTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
        insert picklistLibrariesList;

        // Create Account 
        List<Account> accountsList = TestDataCreator.createClients(
            1, 
            invoiceTermsList[0].Id,
            picklistLibrariesList[0].Id
        );
        insert accountsList;

        // create credit checks
        List<Credit_Check__c> creditChecksList = TestDataCreator.createCreditChecks(
            1, 
            accountsList[0].Id
        );
        insert creditChecksList;
        accountsList[0].Credit_Check__c = creditChecksList[0].Id;
        update accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].InTimeId__c = '123456';
        contactsList[0].LeavingDate__c = System.today().addDays(-1 * IntimeSetting.getWorkerWithNoTimesheetPeriod());
        insert contactsList;
    }

    /**
    *   @description : Test IntimeLeaverSyncBatch
    **/
    @isTest
    static void test_IntimeLeaverSyncBatch(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<Contact> contactsList = [SELECT Id, LeaverInformationUpdatedInInTime__c FROM Contact LIMIT 1];
        Assert.isFalse(contactsList[0].LeaverInformationUpdatedInInTime__c);
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_LEAVER]);

        // create intime sync item
        Database.executeBatch(new IntimeLeaverSyncBatch(),1);
        Test.stopTest();
        contactsList = [SELECT Id, LeaverInformationUpdatedInInTime__c FROM Contact LIMIT 1];
        Assert.isTrue(contactsList[0].LeaverInformationUpdatedInInTime__c);
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_LEAVER]);
    }
}