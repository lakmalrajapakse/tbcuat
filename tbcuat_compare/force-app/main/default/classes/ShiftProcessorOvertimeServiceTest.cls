/**
* @description Test class for Shift Processor Overtime Service
**/
@isTest(seeAllData=false)
private with sharing class ShiftProcessorOvertimeServiceTest {
    
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
        contractsList[0].Plugin__c = 'ShiftProcessorOvertimeService';
        contractsList[0].sirenum__PayrollCycle__c = payrollCyclesList[0].Id;
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        jobRolesList[0].sirenum__Account__c = contractsList[0].Id;
        insert jobRolesList;

        // Create shifts
        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            2,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            null
        );
        insert shiftsList;
    }

    /**
    *   @description : Test getOvertimeBaselineFor
    **/
    @isTest
    static void test_getOvertimeBaselineFor(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(0,cls.getOvertimeBaselineFor(
            shiftsList[0],
            System.now(),
            null,
            (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
        ));
        Test.stopTest();
    }

    /**
    *   @description : Test getRelatedData
    **/
    @isTest
    static void test_getRelatedData(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(null,cls.getRelatedData(
            System.now(),
            System.now().addHours(4),
            (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
        ));
        Test.stopTest();
    }

     /**
    *   @description : Test getRequiredFieldPaths
    **/
    @isTest
    static void test_getRequiredFieldPaths(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(0,cls.getRequiredFieldPaths((new sirenum.ShiftProcessorOvertimeContextBuilder()).build()).size());
        Test.stopTest();
    }

    /**
    *   @description : Test getStartOfDayFor
    **/
    @isTest
    static void test_getStartOfDayFor(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(null,cls.getStartOfDayFor(
            shiftsList[0],
            (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
        ));
        Test.stopTest();
    }

    /**
    *   @description : Test getStartOfWeekFor
    **/
    @isTest
    static void test_getStartOfWeekFor(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(System.today(),cls.getStartOfWeekFor(
            shiftsList[0],
            (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
        ).date());
        Test.stopTest();
    }

    /**
    *   @description : Test isNomineeRelevantAsPastWork
    **/
    @isTest
    static void test_isNomineeRelevantAsPastWork(){
        Test.startTest();
        List<sirenum__Shift__c> shiftsList = [SELECT Id, sirenum__Billable_Calculated_Start_Time__c, sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c, 
            sirenum__Team__r.sirenum__Account__r.sirenum__Client__c, sirenum__Contract__r.Plugin__c FROM sirenum__Shift__c];
        ShiftProcessorOvertimeService cls = new ShiftProcessorOvertimeService();
        Assert.areEqual(true,cls.isNomineeRelevantAsPastWork(
            shiftsList[0],
            shiftsList[1],
            null,
            (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
        ));
        Test.stopTest();
    }
}