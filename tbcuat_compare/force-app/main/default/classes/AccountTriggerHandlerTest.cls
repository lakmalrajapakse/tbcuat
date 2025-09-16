/**
*   @description Test class for IntimeRecordProcessorBatch
**/
@isTest(seeAllData=false)
private with sharing class AccountTriggerHandlerTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create regions
        List<Region__c> regionsList = TestDataCreator.createRegions(1);
        insert regionsList;

        // Create areas
        List<Area__c> areasList = TestDataCreator.createAreas(
            1,
            regionsList[0].Id
        );
        insert areasList;

        // Create branches
        List<Branch__c> branchesList = TestDataCreator.createBranches(
            1,
            areasList[0].Id
        );
        insert branchesList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(
            1,
            branchesList[0].Id
        );
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
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        List<Account> accountsList = [SELECT Id, Name FROM Account LIMIT 1];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Client__c =: accountsList[0].Id]);
        accountsList[0].Name = 'Test';
        update accountsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Client__c =: accountsList[0].Id]);
        Assert.areEqual(2,[SELECT COUNT() FROM AccountShare WHERE AccountId =: accountsList[0].Id AND RowCause = 'Manual']);
    }
}