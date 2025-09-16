/**
* @description Test class for Shift Processor Overtime Handler
**/
@isTest(seeAllData=false)
private with sharing class TimesheetResultsListenerHandlerTest {

    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // Create Invoice Terms 
        List<sirenum__Payroll_Cycle__c> payrollCyclesList = TestDataCreator.createPayrollCycles(1);
        insert payrollCyclesList;

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
        insert contactsList;

        // Create sites
        List<sirenum__Site__c> sitesList = TestDataCreator.createSites(1);
        insert sitesList;

        // Create contracts
        List<sirenum__ProActiveContract__c> contractsList = TestDataCreator.createContracts(
            1,
            accountsList[0].Id
        );
        contractsList[0].Plugin__c = 'TimesheetResultsListenerService';
        contractsList[0].sirenum__PayrollCycle__c = payrollCyclesList[0].Id;
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        jobRolesList[0].sirenum__Account__c = contractsList[0].Id;
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
        rateCardPagesList[0].sirenum__Condition_Field__c = 'Job_Role_Name__c';
        rateCardPagesList[0].sirenum__Condition_Operator__c = 'Equal To';
        rateCardPagesList[0].sirenum__Condition_Value__c = 'Job Role Test_Threshold';
        insert rateCardPagesList;        

        // create rate card lines
        List<sirenum__Rate_Line__c> rateLinesList = TestDataCreator.createRateLines(
            1,
            new Map<Id,sirenum__Rate_Card_Page__c>(rateCardPagesList).keySet(),
            null
        );
        rateLinesList[0].sirenum__Overtime_Pay_Rate__c = 50.00;
        rateLinesList[0].sirenum__Overtime_Charge_Rate__c = 60.00;
        insert rateLinesList;        

        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            6,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            timesheetLine.sirenum__Rate_Line__c = rateLinesList[0].Id;
            timesheetLine.sirenum__RateType__c = 'Hourly';
        }
        timesheetLinesList[5].sirenum__RateType__c = 'Overtime';
        timesheetLinesList[5].Manual_Line_Type__c = 'Shift Allowance';
        insert timesheetLinesList;
    }

    /**
    *   @description : Test handleEvent
    **/
    @isTest
    static void test_handleEvent(){
        Test.startTest();
        List<sirenum__Timesheet_Line__c> timesheetLinesList = [SELECT Id, sirenum__Rate__c, sirenum__Charge__c FROM sirenum__Timesheet_Line__c WHERE sirenum__RateType__c = 'Overtime' LIMIT 1];
        Assert.areEqual(40.00, timesheetLinesList[0].sirenum__Rate__c);
        Assert.areEqual(50.00, timesheetLinesList[0].sirenum__Charge__c);
        // Approve timesheets
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, RebateAmount__c FROM sirenum__Timesheet__c LIMIT 1];
        sirenum.TimesheetResultsEventBuilder timesheetResultsEventBuilder = new sirenum.TimesheetResultsEventBuilder();
        timesheetResultsEventBuilder.setIds(new List<Id>(new Map<Id, sirenum__Timesheet__c>(timesheetsList).keySet()));
        TimesheetResultsListenerHandler cls = new TimesheetResultsListenerHandler();
        cls.handleEvent(timesheetResultsEventBuilder.build());
        Test.stopTest();
        timesheetLinesList = [SELECT Id, sirenum__Rate__c, sirenum__Charge__c FROM sirenum__Timesheet_Line__c WHERE sirenum__RateType__c = 'Overtime' LIMIT 1];
        Assert.areEqual(50.00, timesheetLinesList[0].sirenum__Rate__c);
        Assert.areEqual(60.00, timesheetLinesList[0].sirenum__Charge__c);
    }
}