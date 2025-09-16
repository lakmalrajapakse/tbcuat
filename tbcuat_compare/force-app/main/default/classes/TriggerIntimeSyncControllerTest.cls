/**
*   @description Test class for TriggerIntimeSyncController
**/
@isTest(seeAllData=false)
private with sharing class TriggerIntimeSyncControllerTest {
    
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

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            accountsList[0].Id,
            null,
            null,
            null,
            null
        );
        intimeSyncItemsList[0].Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
        insert intimeSyncItemsList;
    }

    /**
    *   @description : Test triggerSync
    **/
    @isTest
    static void test_triggerSync(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<InTimeSyncItem__c> intimeSyncItems = [SELECT Id FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED LIMIT 1];
        Assert.areEqual(1, [SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED]);
       
        Apexpages.standardSetController standardSetController = new Apexpages.standardSetController(intimeSyncItems);
        standardSetController.setSelected(intimeSyncItems);

        // Call the TriggerIntimeSyncController
        TriggerIntimeSyncController cls = new TriggerIntimeSyncController(standardSetController);
        cls.triggerSync();
        cls.returnToListViewPage();

        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED]);
    }
}