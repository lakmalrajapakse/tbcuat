/**
* @description Test class for Content document link trigger handler
**/
@isTest(seeAllData=false)
public with sharing class ContentDocumentLinkTriggerHandlerTest {
    
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
        contactsList[0].LeaverInformationUpdatedInInTime__c = true;
        insert contactsList;

        // Create sites
        List<sirenum__Site__c> sitesList = TestDataCreator.createSites(1);
        insert sitesList;

        // Create contracts
        List<sirenum__ProActiveContract__c> contractsList = TestDataCreator.createContracts(
            1,
            accountsList[0].Id
        );
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        insert jobRolesList;

        // Create placements
        List<sirenum__Placement__c> placementsList = TestDataCreator.createPlacements(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id
        );
        insert placementsList;

        // Create payroll cycles
        List<sirenum__Payroll_Cycle__c> payrollCyclesList = TestDataCreator.createPayrollCycles(1);
        insert payrollCyclesList;

        // Create weeks
        List<sirenum__Week__c> weeksList = TestDataCreator.createWeeks(
            1,
            payrollCyclesList[0].Id
        );
        insert weeksList;

        // Create timesheets
        List<sirenum__Timesheet__c> timesheetsList = TestDataCreator.createTimesheets(
            1,
            accountsList[0].Id,
            contractsList[0].Id,
            weeksList[0].Id,
            contactsList[0].Id
        );
        insert timesheetsList;

        // Create shifts
        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            placementsList[0].Id
        );
        insert shiftsList;

        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        insert timesheetLinesList;
        timesheetsList[0].IntimeId__c = '123456';
        update timesheetsList;

        // Create Expenses
        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        insert expensesList;
    }

    /**
    *   @description : Test afterInsert
    **/
    @isTest
    static void test_afterInsert(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);

        // create documents
        // create content versions 
        List<ContentVersion> contentVersionsList = TestDataCreator.createContentVersion(1);
        insert contentVersionsList;

        // create content document link
        List<ContentDocumentLink> contentDocumentLinksList = TestDataCreator.createContentDocumentLinks(
            new Map<Id, ContentVersion>(contentVersionsList).keySet(),
            new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet()
        );
        insert contentDocumentLinksList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
    }
}