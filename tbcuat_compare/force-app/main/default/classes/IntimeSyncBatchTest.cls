/**
*   @description Test class for IntimeRecordProcessorBatch
**/
@isTest(seeAllData=false)
public with sharing class IntimeSyncBatchTest {
    
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
        contactsList[0].InTimeExternalId__c = 'Person-2';
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
        accountsList = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        jobRolesList[0].Name = accountsList[0].Client_Code__c+' - Test Driver';
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

        // Create Expenses
        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        insert expensesList;

        // create content versions 
        List<ContentVersion> contentVersionsList = TestDataCreator.createContentVersion(1);
        insert contentVersionsList;

        // create content document link
        List<ContentDocumentLink> contentDocumentLinksList = TestDataCreator.createContentDocumentLinks(
            new Map<Id, ContentVersion>(contentVersionsList).keySet(),
            new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet()
        );
        insert contentDocumentLinksList;

        // create employee request
        List<sirenum__Employee_Request__c> employeeRequestsList = TestDataCreator.createEmployeeRequests(
            1,
            contactsList[0].Id
        );
        insert employeeRequestsList;
    }

    /**
    *   @description : Test IntimeSyncBatchForClient
    **/
    @isTest
    static void test_IntimeSyncBatchForClient(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<Account> accountsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeManagerId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM Account LIMIT 1];
        Assert.areEqual(null, accountsList[0].InTimeId__c);
        Assert.areEqual(null, accountsList[0].InTimeManagerId__c);
        Assert.areEqual('Not Synced', accountsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, accountsList[0].LastIntimeSync__c);

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            accountsList[0].Id,
            null,
            null,
            null,
            null
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        accountsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeManagerId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM Account LIMIT 1];
        Assert.areEqual('22876', accountsList[0].InTimeId__c);
        Assert.areEqual('Synced', accountsList[0].InTimeSyncStatus__c);
        Assert.areNotEqual(null, accountsList[0].LastIntimeSync__c);
    }

    /**
    *   @description : Test IntimeSyncBatchForContact
    **/
    @isTest
    static void test_IntimeSyncBatchForContact(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<Contact> contactsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c, LeaverInformationUpdatedInInTime__c FROM Contact LIMIT 1];
        contactsList[0].LeaverInformationUpdatedInInTime__c = true;
        update contactsList;
        Assert.areEqual(null, contactsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', contactsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, contactsList[0].LastIntimeSync__c);
        Assert.isTrue(contactsList[0].LeaverInformationUpdatedInInTime__c);

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            contactsList[0].Id,
            null,
            null,
            null
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        contactsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c, LeaverInformationUpdatedInInTime__c FROM Contact LIMIT 1];
        Assert.areEqual('134670', contactsList[0].InTimeId__c);
        Assert.areEqual('Synced', contactsList[0].InTimeSyncStatus__c);
        Assert.areNotEqual(null, contactsList[0].LastIntimeSync__c);
        Assert.isFalse(contactsList[0].LeaverInformationUpdatedInInTime__c);
    }

    /**
    *   @description : Test IntimeSyncBatchForPlacement
    **/
    @isTest
    static void test_IntimeSyncBatchForPlacement(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Placement__c> placementsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Placement__c LIMIT 1];
        Assert.areEqual(null, placementsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', placementsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, placementsList[0].LastIntimeSync__c);

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            placementsList[0].Id,
            null,
            null
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        placementsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Placement__c LIMIT 1];
        Assert.areEqual('863080', placementsList[0].InTimeId__c);
        Assert.areEqual('Synced', placementsList[0].InTimeSyncStatus__c);
        Assert.areNotEqual(null, placementsList[0].LastIntimeSync__c);
    }

    /**
    *   @description : Test IntimeSyncBatchForTimesheet
    **/
    @isTest
    static void test_IntimeSyncBatchForTimesheet(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(null, timesheetsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, timesheetsList[0].LastIntimeSync__c);

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            null,
            timesheetsList[0].Id,
            null
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual('1210910', timesheetsList[0].InTimeId__c);
        Assert.areEqual('Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areNotEqual(null, timesheetsList[0].LastIntimeSync__c);
    }

    /**
    *   @description : Test IntimeSyncBatchForTimesheet
    **/
    @isTest
    static void test_IntimeSyncBatchForTimesheetWithId(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(null, timesheetsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, timesheetsList[0].LastIntimeSync__c);
        timesheetsList[0].InTimeId__c = '1210910';
        update timesheetsList;

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            null,
            timesheetsList[0].Id,
            null
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual('1210910', timesheetsList[0].InTimeId__c);
        Assert.areEqual('Synced', timesheetsList[0].InTimeSyncStatus__c);
        List<sirenum__Expense__c> expensesList = [SELECT Id, InTimeId__c FROM sirenum__Expense__c LIMIT 1];
        //Assert.areEqual('2732', expensesList[0].InTimeId__c);
    }

    /**
    *   @description : Test IntimeSyncBatchForCEmployee Request
    **/
    @isTest
    static void test_IntimeSyncBatchForEmployeeRequest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<Contact> contactsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c, LeaverInformationUpdatedInInTime__c FROM Contact LIMIT 1];
        contactsList[0].InTimeId__c = '12124';
        update contactsList;
        List<sirenum__Employee_Request__c> employeeRequestsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Employee_Request__c LIMIT 1];
        Assert.areEqual(null, employeeRequestsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', employeeRequestsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, employeeRequestsList[0].LastIntimeSync__c);

        // create intime sync item
        List<InTimeSyncItem__c> intimeSyncItemsList = TestDataCreator.createIntimeSyncItems(
            null,
            null,
            null,
            null,
            employeeRequestsList[0].Id
        );
        insert intimeSyncItemsList;
        IntimeSyncProcessor.startIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        Test.stopTest();
        employeeRequestsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Employee_Request__c LIMIT 1];
        Assert.areEqual('57263', employeeRequestsList[0].InTimeId__c);
        Assert.areEqual('Synced', employeeRequestsList[0].InTimeSyncStatus__c);
        Assert.areNotEqual(null, employeeRequestsList[0].LastIntimeSync__c);
    }
}