/**
*   @description Test class for IntimeRecordProcessorBatch
**/
@isTest(seeAllData=false)
private with sharing class IntimeReverseSyncBatchTest {
    
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

        // create content versions 
        List<ContentVersion> contentVersionsList = TestDataCreator.createContentVersion(1);
        insert contentVersionsList;

        // create content document link
        List<ContentDocumentLink> contentDocumentLinksList = TestDataCreator.createContentDocumentLinks(
            new Map<Id, ContentVersion>(contentVersionsList).keySet(),
            new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet()
        );
        insert contentDocumentLinksList;
    }

    /**
    *   @description : Test IntimeReverseSyncBatchForWorker
    **/
    @isTest
    static void test_IntimeReverseSyncBatchForWorker(){
        Test.startTest();
        Assert.areEqual(0, [SELECT COUNT() fROM InTimeSyncItem__c WHERE Person__c != null AND IsReverse__c = true AND Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS]);
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<Contact> contactsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM Contact LIMIT 1];
        Assert.areEqual(null, contactsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', contactsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, contactsList[0].LastIntimeSync__c);
        contactsList[0].InTimeId__c = '134670';
        update contactsList;

        // create intime sync item
        Database.executeBatch(new IntimeReverseSyncBatch(0),1);
        Test.stopTest();
        contactsList = [SELECT Id, InTimeId__c, InTimeExternalId__c, InTimeSyncStatus__c, LastIntimeSync__c, InPayReference__c FROM Contact LIMIT 1];
        Assert.areEqual('Person-2', contactsList[0].InPayReference__c);
        Assert.areEqual(1, [SELECT COUNT() fROM InTimeSyncItem__c WHERE Person__c != null AND IsReverse__c = true AND Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS]);
    }

    /**
    *   @description : Test IntimeSyncBatchForTimesheet
    **/
    @isTest
    static void test_IntimeReverseSyncBatchForTimesheet(){
        Test.startTest();
        Assert.areEqual(0, [SELECT COUNT() fROM InTimeSyncItem__c WHERE Timesheet__c != null AND IsReverse__c = true AND Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS]);
        Test.setMock(HttpCalloutMock.class, new IntimeCalloutMock());
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(null, timesheetsList[0].InTimeId__c);
        Assert.areEqual('Not Synced', timesheetsList[0].InTimeSyncStatus__c);
        Assert.areEqual(null, timesheetsList[0].LastIntimeSync__c);
        timesheetsList[0].InTimeId__c = '1210910';
        update timesheetsList;
        // create intime sync item
        Database.executeBatch(new IntimeReverseSyncBatch(1),1);
        Test.stopTest();
        timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual('1210910', timesheetsList[0].InTimeId__c);
        Assert.areEqual(1, [SELECT COUNT() fROM InTimeSyncItem__c WHERE Timesheet__c != null AND IsReverse__c = true AND Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS]);
    }
}