/**
*   @description Test class for InpayController
**/
@isTest(seeAllData=false)
public with sharing class InpayControllerTest {
    
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
        contactsList[0].InTimeExternalId__c = 'E1233434';
        contactsList[0].InPayReference__c = 'E1233434';
        update contactsList;
    }

    /**
    *   @description : Test getHolidayScheme
    **/
    @isTest
    static void test_getHolidayScheme(){
        Test.startTest();
        List<Contact> contactsList = [SELECT Id FROM Contact LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        IntimeCalloutMock.systemName = 'Inpay';
        Map<String, Object> objectsMap = InpayController.getHolidayScheme(contactsList[0].Id);
        Assert.areEqual('[ { "SchemeName": "Holiday Scheme", "RolledOverDays": 10.000000000, "EffectiveDate": "2024-10-22T00:00:00", "AccrueDaysOverride": null, "AccruedYTD": 0.00000000, "TakenYTD": 0.0000000000000, "AverageRate": 0.0000, "AllowNegative": false, "EndDate": null, "AverageRateOverride": null } ]',String.valueOf(objectsMap.get('holidayScheme')));
        Test.stopTest();
    }
}