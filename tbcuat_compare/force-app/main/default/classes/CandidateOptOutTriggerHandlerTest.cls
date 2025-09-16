/**
* @description Test class for candidate optout
**/
@isTest(seeAllData=false)
private with sharing class CandidateOptOutTriggerHandlerTest {
    
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

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].Plan_Code__c = picklistLibrariesList[0].Id;
        insert contactsList;

        // create contacts 
        List<TR1__Email_Type__c> emailTypesList =  TestDataCreator.createEmailType(
            1
        );
        insert emailTypesList;

        // Create candidate consent
         List<TR1__Candidate_Opt_Out__c> candidateOptoutsList = TestDataCreator.createCandidateOptOuts(
            1,
            contactsList[0].Id,
            emailTypesList[0].Id
        );
        insert candidateOptoutsList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<TR1__Candidate_Opt_Out__c> candidateOptoutsList = [SELECT Id FROM TR1__Candidate_Opt_Out__c LIMIT 1];
        update candidateOptoutsList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM TR1__Candidate_Opt_Out__Share WHERE ParentId =: candidateOptoutsList[0].Id AND RowCause = 'PlanCode__c']);
    }
    
}