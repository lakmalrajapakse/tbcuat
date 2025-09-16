/**
* @description Test class for Timesheet Trigger Handler
**/
@isTest(seeAllData=false)
public with sharing class TimesheetTriggerHandlerTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
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
    }

    /**
    *   @description : Test before Update 
    **/
    @isTest
    static void test_beforeUpdate(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        // Approve timesheets
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, RebateAmount__c FROM sirenum__Timesheet__c LIMIT 1];
        List<sirenum__Shift__c> shiftsList = [SELECT Id FROM sirenum__Shift__c];
        Assert.areEqual(0.00,timesheetsList[0].RebateAmount__c);
        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        insert timesheetLinesList;
        update timesheetsList;
        timesheetsList = [SELECT Id, RebateAmount__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(0.00,timesheetsList[0].RebateAmount__c);
        Test.stopTest();
    }

    /**
    *   @description : Test afterUpdate 
    **/
    @isTest
    static void test_afterUpdate(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
        // Approve timesheets
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, Status__c FROM sirenum__Timesheet__c LIMIT 1];
        timesheetsList[0].Status__c = IntimeConstants.TIMESHEET_STATUS_APPROVED;
        update timesheetsList;
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
        timesheetsList[0].IntimeId__c = '123456';
        update timesheetsList;
        timesheetsList[0].Status__c = 'Exported';
        try{
            update timesheetsList;
        }catch(Exception ex){
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
    }

    /**
    *   @description : Test before delete 
    **/
    @isTest
    static void test_beforeDelete(){
        Test.startTest();
        delete [SELECT Id FROM InTimeSyncItem__c];
        Assert.areEqual(0,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
        // Approve timesheets
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, Status__c FROM sirenum__Timesheet__c LIMIT 1];
        timesheetsList[0].IntimeId__c = '123456';
        timesheetsList[0].Status__c = IntimeConstants.TIMESHEET_STATUS_APPROVED;
        update timesheetsList;
        Assert.areEqual(1,[SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED]);
        try{
            delete timesheetsList;
        }catch(Exception ex){
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
    }
}