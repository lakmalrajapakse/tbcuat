/**
*   @description Test class for IntimeRecordProcessorBatch
**/
@isTest(seeAllData=false)
private with sharing class AdditionalClientEmailTriggerHandler_test {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        invoiceTermsList[0].TimesheetsOnInvoices__c = InvoiceTerm__c.TimesheetsOnInvoices__c.getDescribe().getPicklistValues().get(0).getValue();
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
    static void test_afterChange() {
        Account client = [select id from Account limit 1];

        List<Additional_Client_Email__c> ace =  new List<Additional_Client_Email__c>{
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't1_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't2_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't3_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't4_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't5_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't6_1234567891012@this.veryverylongemailaddress.com'
            ),
            new Additional_Client_Email__c (            
                Client__c = client.Id,
                Type__c = 'Invoice',
                Email__c = 't6_1234567891012@this.veryverylongemailaddress.com'
            )
        };            

        insert ace;

        Test.startTest();
        ace[2].Email__c = 't3update_1234567891012@this.veryverylongemailaddress.com';
        update ace[2];


        delete new List<Additional_Client_Email__c> {ace[3], ace[4]};

        undelete ace[4];

        Test.stopTest();
        

    }
}