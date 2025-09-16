/**
* @description Test class for case management trigger handler 
**/
@isTest(seeAllData=false)
private with sharing class CaseManagementTriggerHandlerTest {
    
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
        contactsList[0].TR1__Candidate_Status__c = 'Registered';
        insert contactsList;

        insert new CaseManagement__c(
            Associated_Worker_Candidate__c = contactsList[0].Id,
            Type_of_Case__c = CaseManagement__c.Type_of_Case__c.getDescribe().getPicklistValues()[0].getValue(), 
            Brief_Description__c = 'Test Case' 
        );
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<CaseManagement__c> cm = [SELECT Id FROM CaseManagement__c LIMIT 1];
        update cm;
        Test.stopTest();        
        Assert.areEqual(2,[SELECT COUNT() FROM CaseManagement__Share WHERE ParentId =: cm[0].Id AND RowCause = 'Plan_Code__c']);
    }
}