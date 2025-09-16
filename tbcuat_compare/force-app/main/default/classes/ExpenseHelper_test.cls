/**
*   @description Test class for ExpenseHelper
**/
@isTest(seeAllData=false)
public with sharing class ExpenseHelper_test {
    
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
        jobRolesList[0].sirenum__AWR_Group__c = sirenum__Team__c.sirenum__AWR_Group__c.getDescribe().getPicklistValues().get(0).getValue();
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

        // Create Expenses Type
        List<sirenum__Expense_Type__c> expenseTypesList = new List<sirenum__Expense_Type__c> {
            new sirenum__Expense_Type__c(
                Name = 'Expense Type = Taxable',
                TAX_VAT__c = true,
                sirenum__Value__c= 100) ,
            new sirenum__Expense_Type__c(   
                Name = 'Expense Type = Non Taxable',
                TAX_VAT__c = false,
                sirenum__Value__c= 100)            
        };
        insert expenseTypesList;
    }

    /**
    *   @description : Test add expense
    **/
    @isTest
    static void test_addExpenseTimesheet(){
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];
        
        Test.startTest();
        // Create Expenses
        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        expensesList[0].ChargeExpenseValue__c = 100;
        expensesList[0].Expense_Value__c = 80;
        insert expensesList;
        Test.stopTest();

        timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];

        Assert.areEqual(80, timesheetsList[0].sirenum__Non_Taxed_Expenses__c);
        Assert.areEqual(100, timesheetsList[0].Non_Taxed_Charged_Expenses__c);    
    }
    
    /**
    *   @description : Test update expense
    **/
    @isTest
    static void test_updateExpenseTimesheet(){
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];
        List<sirenum__Expense_Type__c> expenseTypesList = [SELECT Id, Name, TAX_VAT__c FROM sirenum__Expense_Type__c where TAX_VAT__c = true];

        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        expensesList[0].sirenum__Expense_Type__c = expenseTypesList[0].Id;
        expensesList[0].ChargeExpenseValue__c = 100;
        expensesList[0].Expense_Value__c = 80;
        insert expensesList;

        Test.startTest();
        // Update Expenses
        update new sirenum__Expense__c(id = expensesList[0].Id, ChargeExpenseValue__c = 200, Expense_Value__c = 160);
        Test.stopTest();

        timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];

        Assert.areEqual(160, timesheetsList[0].sirenum__Taxed_Expenses__c);
        Assert.areEqual(200, timesheetsList[0].Taxed_Charged_Expenses__c);    
    }

    /**
    *   @description : Test delete expense
    **/
    @isTest
    static void test_deleteExpenseTimesheet(){
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];

        List<sirenum__Expense__c> expensesList = TestDataCreator.createExpenses(
            1,
            timesheetsList[0].Id
        );
        expensesList[0].ChargeExpenseValue__c = 100;
        expensesList[0].Expense_Value__c = 80;
        insert expensesList;

        Test.startTest();
        // Update Expenses
        delete expensesList;
        Test.stopTest();

        timesheetsList = [SELECT Id, sirenum__Non_Taxed_Expenses__c, sirenum__Taxed_Expenses__c, Non_Taxed_Charged_Expenses__c, Taxed_Charged_Expenses__c FROM sirenum__Timesheet__c LIMIT 1];

        Assert.areEqual(0, timesheetsList[0].sirenum__Taxed_Expenses__c);
        Assert.areEqual(0, timesheetsList[0].Taxed_Charged_Expenses__c);    
    }
}