/**
*   @description Test class for BankDetailsTriggerHandler
**/
@isTest(seeAllData=false)
public with sharing class BankDetailsTriggerHandlerTest {
    
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

        // create bank details
        List<Bank_Details__c> bankDetailsList = TestDataCreator.createBankDetails(
            1,
            contactsList[0].Id
        );
        insert bankDetailsList;
        contactsList[0].Active_Bank_Details__c = bankDetailsList[0].Id;
        contactsList[0].IntimeId__c = '123456';
        update contactsList;
    }

     /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        delete [SELECT Id FROM InTimeSyncItem__c];
        List<Contact> contactsList = [SELECT Id, FirstName FROM Contact WHERE Active_Bank_Details__c != null LIMIT 1];
        List<Bank_Details__c> bankDetailsList = [SELECT Id, Bank_Account_Number__c FROM Bank_Details__c LIMIT 1];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Person__c =: contactsList[0].Id]);
        bankDetailsList[0].Bank_Account_Number__c = '12345677';
        update bankDetailsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED AND Person__c =: contactsList[0].Id]);
    }
}