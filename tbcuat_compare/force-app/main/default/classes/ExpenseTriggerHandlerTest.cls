/**
* @description Test class for expense trigger handler
**/
@isTest(seeAllData=false)
private with sharing class ExpenseTriggerHandlerTest {
    
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
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<sirenum__Expense__c> expensesList = [SELECT Id FROM sirenum__Expense__c LIMIT 1];
        update expensesList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM sirenum__Expense__Share WHERE ParentId =: expensesList[0].Id AND RowCause = 'PlanCode__c']);
    }
}