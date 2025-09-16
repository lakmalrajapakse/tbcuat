/**
* @description Test class for chat Message
**/
@isTest(seeAllData=false)
public with sharing class ChatMessageTriggerHandlerTest {
    
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


        // Create candidate consent
        List<b3o__Chat_Message__c> chatMessagesList = TestDataCreator.createChatMessages(
            1,
            contactsList[0].Id
        );
        insert chatMessagesList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<b3o__Chat_Message__c> chatMessagesList = [SELECT Id FROM b3o__Chat_Message__c LIMIT 1];
        update chatMessagesList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM b3o__Chat_Message__Share WHERE ParentId =: chatMessagesList[0].Id AND RowCause = 'PlanCode__c']);
    }
}