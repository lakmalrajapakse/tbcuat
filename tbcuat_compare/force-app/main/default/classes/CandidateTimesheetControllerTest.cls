/**
* @description Test class for CandidateTimesheetController
**/
@isTest(seeAllData=false)
private with sharing class CandidateTimesheetControllerTest {
    
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
        jobRolesList[0].sirenum__AWR_Group__c= sirenum__Team__c.sirenum__AWR_Group__c.getDescribe().getPicklistValues().get(0).getValue();        
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
    *   @description : Test getShifts
    **/
    @isTest
    static void test_getShifts(){
        Test.startTest();
        List<Contact> contactsList = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> objectsMap = CandidateTimesheetController.getShifts(contactsList[0].Id,System.today());
        List<Object> datesList = (List<Object>)objectsMap.get('datesList');
        List<CandidateTimesheetController.Shift> shiftsList = (List<CandidateTimesheetController.Shift>)objectsMap.get('shifts');
        Test.stopTest();
        Assert.areEqual(7,datesList.size());
        Assert.areEqual(1,shiftsList.size());
    }

    /**
    *   @description : Test updateshifts
    **/
    @isTest
    static void test_updateShifts(){
        Test.startTest();
        DateTime dateTimeToSet = DateTime.now().addHours(2);
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Shift__c WHERE sirenum__Actual_Start_Time__c =: dateTimeToSet]);
        List<Contact> contactsList = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> objectsMap = CandidateTimesheetController.getShifts(contactsList[0].Id,System.today());
        List<Object> datesList = (List<Object>)objectsMap.get('datesList');
        List<CandidateTimesheetController.Shift> shiftsList = (List<CandidateTimesheetController.Shift>)objectsMap.get('shifts');
        List<sirenum__Shift__c> shiftRecordsList = [SELECT Id, sirenum__Actual_Start_Time__c FROM sirenum__Shift__c LIMIT 1];
        shiftRecordsList[0].sirenum__Actual_Start_Time__c = dateTimeToSet;
        CandidateTimesheetController.updateShifts(JSON.serialize(shiftRecordsList));
        Test.stopTest();
        Assert.areEqual(7,datesList.size());
        Assert.areEqual(1,shiftsList.size());
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Shift__c WHERE sirenum__Actual_Start_Time__c =: dateTimeToSet]);
    }
}