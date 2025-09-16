/**
*   @description Test class for IntimeFinancialTagSendBatch
**/
@isTest(seeAllData=false)
public with sharing class IntimeFinancialTagSendBatchTest {
    
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
    }

    /**
    *   @description : Test IntimeFinancialTagSendBatch
    **/
    @isTest
    static void test_IntimeFinancialTagSendBatch(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        Assert.areEqual(0, [SELECT COUNT() FROM InTimeSyncItem__c WHERE Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_GROUP_CODE]);
        Database.executeBatch(new IntimeFinancialTagSendBatch(
            new Set<String>{
                IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_GROUP_CODE_SUBMIT
            }
        ),1);
        Test.stopTest();
        Assert.areEqual(1, [SELECT COUNT() FROM InTimeSyncItem__c WHERE Type__c =: IntimeConstants.SALESFORCE_TO_INTIME_GROUP_CODE]);
    }
}