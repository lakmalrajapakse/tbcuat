/**
* @description Test class for TimesheetLine Trigger Handler
**/
@isTest(seeAllData=false)
private with sharing class TimesheetLineTriggerHandlerTest {

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
        contactsList[0].Do_you_have_the_right_to_work_in_the_UK__c = true;
        contactsList[0].Do_you_currently_live_in_the_UK__c = true;
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

        // create rate cards
        List<sirenum__Rate_Card__c> rateCardsList = TestDataCreator.createRateCards(
            1
        );
        insert rateCardsList;

        // create rate card pages
        List<sirenum__Rate_Card_Page__c> rateCardPagesList = TestDataCreator.createRateCardPages(
            1,
            new Map<Id,sirenum__Rate_Card__c>(rateCardsList).keySet() 
        );
        insert rateCardPagesList;

        // create rate codes
        List<Rate_Code__c> rateCodesList = TestDataCreator.createRateCodes(
            1
        );
        insert rateCodesList;

        // create standard rate types
        List<sirenum__Standard_Rate_Type__c> rateTypesList = TestDataCreator.createStandardRateTypes(
            1
        );
        insert rateTypesList;

        // create rate card lines
        List<sirenum__Rate_Line__c> rateLinesList = TestDataCreator.createRateLines(
            1,
            new Map<Id,sirenum__Rate_Card_Page__c>(rateCardPagesList).keySet(),
            rateCodesList[0].Id
        );
        rateLinesList[0].sirenum__Standard_Rate_Type__c = rateTypesList[0].Id;
        insert rateLinesList;

        // create rate modifier types
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = TestDataCreator.createRateModifierTypes(
            1
        );
        rateModifierTypesList[0].StandardRateType__c = rateTypesList[0].Id;
        insert rateModifierTypesList;
    }

    /**
    *   @description : Test Before Context
    **/
    @isTest
    static void test_beforeInsert(){
        Test.startTest();
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id FROM sirenum__Timesheet__c];
        List<sirenum__Shift__c> shiftsList = [SELECT Id FROM sirenum__Shift__c];
        List<sirenum__Rate_Line__c> rateLinesList = [SELECT Id FROM sirenum__Rate_Line__c];
        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        timesheetLinesList[0].sirenum__Rate_Line__c = rateLinesList[0].Id;
        insert timesheetLinesList;
        // Approve timesheets
        Test.stopTest(); 
        timesheetLinesList = [SELECT Id, DateUnixEpoch__c, ShiftStartTimeUnixEpoch__c, ShiftEndTimeUnixEpoch__c FROM sirenum__Timesheet_Line__c];
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            Assert.isNotNull(timesheetLine.DateUnixEpoch__c);
            //Assert.isNotNull(timesheetLine.ShiftStartTimeUnixEpoch__c);
            //Assert.isNotNull(timesheetLine.ShiftEndTimeUnixEpoch__c);
        }
    }

     /**
    *   @description : Test Before Update
    **/
    @isTest
    static void test_beforeUpdate(){
        Test.startTest();
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id FROM sirenum__Timesheet__c];
        List<sirenum__Shift__c> shiftsList = [SELECT Id FROM sirenum__Shift__c];
        List<sirenum__Rate_Line__c> rateLinesList = [SELECT Id FROM sirenum__Rate_Line__c];
        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        insert timesheetLinesList;
        timesheetLinesList[0].sirenum__Rate_Line__c = rateLinesList[0].Id;
        update timesheetLinesList;
        // Approve timesheets
        Test.stopTest(); 
        timesheetLinesList = [SELECT Id, DateUnixEpoch__c, ShiftStartTimeUnixEpoch__c, ShiftEndTimeUnixEpoch__c FROM sirenum__Timesheet_Line__c];
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            Assert.isNotNull(timesheetLine.DateUnixEpoch__c);
            //Assert.isNotNull(timesheetLine.ShiftStartTimeUnixEpoch__c);
            //Assert.isNotNull(timesheetLine.ShiftEndTimeUnixEpoch__c);
        }
    }
}