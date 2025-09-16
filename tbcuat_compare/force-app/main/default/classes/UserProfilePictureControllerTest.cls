/**
* @description Apex class used to manage timesheets
**/
@isTest(seeAllData=true)
public with sharing class UserProfilePictureControllerTest {

    /**
    *   @description : set up test data
    **/
    static void setUpTestData(){
        // create rebates
        List<Rebate__c> rebatesList = TestDataCreator.createRebates(1);
        rebatesList[0].Type__c = 'Calculated';
        rebatesList[0].Handler__c = 'RebateCalculationHandler';
        insert rebatesList;

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
        accountsList[0].Rebate__c = rebatesList[0].Id;
        insert accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        insert contactsList;
    }

    /**
    *   @description : Test manageAttachment
    **/
    @isTest
    static void test_manageAttachment(){
        List<Contact> contactsList = [SELECT Id, sirenum__Photo_ID__c FROM Contact LIMIT 1];
        Assert.areEqual(null,contactsList[0].sirenum__Photo_ID__c);
        Test.startTest();
        String attachmentUrl = UserProfilePictureController.manageAttachment(
            'Test',
            contactsList[0].Id,
            'Test'
        );
        Test.stopTest();
        Assert.isNotNull(attachmentUrl);
    }
}