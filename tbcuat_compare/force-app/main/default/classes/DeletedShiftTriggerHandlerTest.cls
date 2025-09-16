/**
* @description Test class for Contract Rate Modifier
**/
@isTest(seeAllData=false)
private with sharing class DeletedShiftTriggerHandlerTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // create rebates
        List<Rebate__c> rebatesList = TestDataCreator.createRebates(1);
        rebatesList[0].Type__c = 'Calculated';
        rebatesList[0].Handler__c = 'RebateCalculationHandler';
        insert rebatesList;

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
        accountsList[0].Rebate__c = rebatesList[0].Id;
        insert accountsList;

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

        // create deleted shifts
        List<sirenum__Deleted_Shift__c> deletedShiftsList = TestDataCreator.createDeletedShifts(
            1,
            jobRolesList[0].Id,
            contactsList[0].Id
        );
        insert deletedShiftsList;    
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<sirenum__Deleted_Shift__c> deletedShiftsList = [SELECT Id FROM sirenum__Deleted_Shift__c LIMIT 1];
        update deletedShiftsList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM sirenum__Deleted_Shift__Share WHERE ParentId =: deletedShiftsList[0].Id AND RowCause = 'PlanCode__c']);
    }
}