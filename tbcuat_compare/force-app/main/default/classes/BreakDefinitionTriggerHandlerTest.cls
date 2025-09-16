/**
* @description Test class for break defintion trigger handler 
**/
@isTest(seeAllData=false)
private with sharing class BreakDefinitionTriggerHandlerTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){
        insert new sirenum__AdaptiveBatchSettings__c(
            sirenum__Classname__c = 'sirenum.ShiftBreakProcessing',
            sirenum__Enabled__c = true,
            sirenum__ChunkSize__c = 20,
            name = 'Shift Break Processing'
        );
        
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

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].Plan_Code__c = picklistLibrariesList[0].Id;
        contactsList[0].TR1__Candidate_Status__c = 'Registered';
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

        // Create break definitions
        List<sirenum__Break_definition__c> breakDefinitionsList = TestDataCreator.createBreakDefinitions(
            1,
            contractsList[0].Id
        );
        insert breakDefinitionsList;

        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            null
        );

        insert shiftsList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<sirenum__Break_definition__c> breakDefinitionsList = [SELECT Id FROM sirenum__Break_definition__c LIMIT 1];
        update breakDefinitionsList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM sirenum__Break_definition__Share WHERE ParentId =: breakDefinitionsList[0].Id AND RowCause = 'PlanCode__c']);
    }
}