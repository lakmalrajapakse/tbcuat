/**
*   @description Test class for InvoiceTermTriggerHandler
**/
@isTest(seeAllData=false)
public with sharing class InvoiceTermTriggerHandlerTest {
    
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
        accountsList[0].IntimeId__c = '123456';
        insert accountsList;
        invoiceTermsList[0].ParentExternalId__c = accountsList[0].Id;
        update invoiceTermsList;

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
        insert contactsList;

        // Create sites
        List<sirenum__Site__c> sitesList = TestDataCreator.createSites(1);
        insert sitesList;

        // Create contracts
        List<sirenum__ProActiveContract__c> contractsList = TestDataCreator.createContracts(
            1,
            accountsList[0].Id
        );
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        accountsList = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        jobRolesList[0].Name = accountsList[0].Client_Code__c+' - Test Driver';
        insert jobRolesList;

        // Create placements
        List<sirenum__Placement__c> placementsList = TestDataCreator.createPlacements(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id
        );
        placementsList[0].InvoiceTerm__c = invoiceTermsList[0].Id;
        placementsList[0].IntimeId__c = '123456';
        insert placementsList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        delete [SELECT Id FROM InTimeSyncItem__c];
        List<Account> accountsList = [SELECT Id, Name FROM Account LIMIT 1];
        List<sirenum__Placement__c> placementsList = [SELECT Id, Name FROM sirenum__Placement__c LIMIT 1];
        List<InvoiceTerm__c> invoiceTermsList = [SELECT Id, Name FROM InvoiceTerm__c LIMIT 1];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Placement__c =: placementsList[0].Id]);
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Client__c =: accountsList[0].Id]);
        invoiceTermsList[0].TermDays__c = 25;
        update invoiceTermsList;
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Client__c =: accountsList[0].Id]);
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Placement__c =: placementsList[0].Id]);
        invoiceTermsList[0].TermDays__c = 27;
        update invoiceTermsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Client__c =: accountsList[0].Id]);
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Placement__c =: placementsList[0].Id]);
        Assert.areEqual(2,[SELECT COUNT() FROM InvoiceTerm__Share WHERE ParentId =: invoiceTermsList[0].Id AND RowCause = 'PlanCode__c']);
    }
}