/**
* @description Test class for Employee Request Trigger Handler
**/
@isTest(seeAllData=false)
public with sharing class EmployeeRequestTriggerHandlerTest {
    
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

        // create contacts 
        List<Contact> contactsList = TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].IntimeId__c = '123456';
        insert contactsList;

        // create employee request
        List<sirenum__Employee_Request__c> employeeRequestsList = TestDataCreator.createEmployeeRequests(
            1,
            contactsList[0].Id
        );
        insert employeeRequestsList;
    }

    /**
    *   @description : Test afterUpdate 
    **/
    @isTest
    static void test_afterUpdate(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
        // Approve employee request
        List<sirenum__Employee_Request__c> employeeRequestsList = [SELECT Id, sirenum__Approved__c FROM sirenum__Employee_Request__c LIMIT 1];
        employeeRequestsList[0].SendToIntime__c = true;
        update employeeRequestsList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
    }
}