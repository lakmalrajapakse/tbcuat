/**
*   @description Test class for ContractorPayslipController
**/
@isTest(seeAllData=false)
private with sharing class ContractorPayslipControllerTest {
    
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
        contactsList[0].InTimeId__c = '120456';
        contactsList[0].InPayId__c = '120456';
        update contactsList;
    }

    /**
    *   @description : Test getContractorPayslip
    **/
    @isTest
    static void test_getContractorPayslip(){
        Test.startTest();
        List<Contact> contactsList = [SELECT Id FROM Contact LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        Assert.areEqual('https://inpay.es.rsmuk.com/selfservice3/login.aspx?a=nNXxKB/ltwzA32efnkNun8jyPPJY/t0JpSS6UkQnZnk=&b=106041&c=1703&d=1741000173500',ContractorPayslipController.getContractorPayslip(contactsList[0].Id));
        Test.stopTest();
    }
}