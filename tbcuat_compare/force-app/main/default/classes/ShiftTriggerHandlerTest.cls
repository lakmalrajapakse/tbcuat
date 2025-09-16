/**
* @description Test class for Shift Trigger Handler
**/
@isTest(seeAllData=false)
private with sharing class ShiftTriggerHandlerTest {
    
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
        insert jobRolesList;
    }

    /**
    *   @description : Test After Insert
    **/
    @isTest
    static void test_afterInsert(){
        Test.startTest();
        List<sirenum__ProActiveContract__c> contractsList = [SELECT Id FROM sirenum__ProActiveContract__c];
        List<sirenum__Team__c> jobRolesList = [SELECT Id FROM sirenum__Team__c];
        List<sirenum__Site__c> sitesList = [SELECT Id FROM sirenum__Site__c];
        List<Contact> contactsList = [SELECT Id FROM Contact];
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Placement__c]);
        // Create shifts
        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            null
        );
        insert shiftsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Placement__c]);
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpdate(){
        Test.startTest();
        List<sirenum__ProActiveContract__c> contractsList = [SELECT Id FROM sirenum__ProActiveContract__c];
        List<sirenum__Team__c> jobRolesList = [SELECT Id FROM sirenum__Team__c];
        List<sirenum__Site__c> sitesList = [SELECT Id FROM sirenum__Site__c];
        List<Contact> contactsList = [SELECT Id FROM Contact];
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Placement__c]);
        // Create shifts
        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            null
        );
        insert shiftsList;
        update shiftsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Placement__c]);
    }
}