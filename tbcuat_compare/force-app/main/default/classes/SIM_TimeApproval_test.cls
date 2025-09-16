/**
 * @description       : 
 * @author            : Simon Coles
 * @group             : 
 * @last modified on  : 20-11-2024
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   20-11-2024   Simon Coles   Initial Version
**/
@isTest
public with sharing class SIM_TimeApproval_test {
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
        accountsList[0].client_code__C = null;
        update accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
        contactsList[0].LeaverInformationUpdatedInInTime__c = true;
        contactsList[0].Do_you_have_the_right_to_work_in_the_UK__c = true;
        contactsList[0].Do_you_currently_live_in_the_UK__c = true;
        contactsList[0].Plan_Code__c = picklistLibrariesList[0].Id;
        contactsList[0].TR1__Candidate_Status__c = 'Registered';
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
        shiftsList[0].sirenum__Timesheet_summaries__c = timesheetsList[0].Id;
        update shiftsList;

        // Create Timesheet lines
        List<sirenum__Timesheet_Line__c> timesheetLinesList = TestDataCreator.createTimesheetLines(
            1,
            timesheetsList[0].Id,
            new Map<Id, sirenum__Shift__c>(shiftsList).keySet()
        );
        insert timesheetLinesList;
    }


    @isTest
    static void test_getSetup() {
        Contact con = [select id from contact];

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.getSetup((String)con.Id));
        system.assertEquals(true, (Boolean)response.get('success'));        
    }

    @isTest
    static void test_getFullRecords_Pos() {
 
        Contact con = [select id from contact limit 1];

        List<String> cons = new List<String>{con.Id};
        String sDate = System.today().day() + '/' + System.today().month() + '/' + System.today().year();
        String eDate = System.today().addDays(7).day() + '/' + System.today().addDays(7).month() + '/' + System.today().addDays(7).year();

        Test.startTest();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.getData(null, sDate, eDate, cons, null,null, null, null, null, 'View All Shifts', 'All'));
        Test.stopTest();

        system.assertEquals(true, (Boolean)response.get('success'), 'Result: ' + response);
        Map<String, Object> responseObjectMap = (Map<String, Object>)response.get('responseObject');

        List<Object> records = (List<Object>)responseObjectMap.get('records');
        system.assertEquals(1, records.size());
    }

    @isTest
    static void test_updateShifts_Pos() {
        List<sirenum__Shift__c> testShifts = [SELECT Id, sirenum__Contact__c, sirenum__Site__c, sirenum__Team__c, sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c FROM sirenum__Shift__c];


        Test.startTest();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.updateShifts(JSON.serialize(testShifts)));
        Test.stopTest();

        system.assertEquals(true, (Boolean)response.get('success'));
        List<Object> responseObjectList = (List<Object>)response.get('responseObject');
        
        for(Object srObject : responseObjectList){
            Map<String,Object> saveResultMap = (Map<String,Object>)srObject;
            system.assertEquals(true, (Boolean)saveResultMap.get('success'));
        }
    }

    
    @isTest
    static void test_processPay() {
        Test.startTest();
        try {
            SIM_TimeApproval.processPay('11/23/2020', '11/30/2020', null, null, null);
        } catch (Exception e) {

        }           
        Test.stopTest();
    }

    @isTest
    static void test_updateShifts_Neg() {
        List<sirenum__Shift__c> testShifts = [SELECT Id, sirenum__Contact__c, sirenum__Site__c, sirenum__Team__c, sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c FROM sirenum__Shift__c];

        //Try to invoke error - a shift must have times
        for(sirenum__Shift__c shift : testShifts){
            //Should trigger standard validation rule "This shift ends before it starts"
            DateTime startTime = shift.sirenum__Scheduled_Start_Time__c;
            shift.sirenum__Scheduled_Start_Time__c = shift.sirenum__Scheduled_End_Time__c;
            shift.sirenum__Scheduled_End_Time__c = startTime;
        }


        Test.startTest();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.updateShifts(JSON.serialize(testShifts)));
        Test.stopTest();

        system.assertEquals(false, (Boolean)response.get('success'));
        List<Object> responseObjectList = (List<Object>)response.get('responseObject');
        

        for(Object srObject : responseObjectList){
            Map<String,Object> saveResultMap = (Map<String,Object>)srObject;
            system.assertEquals(false, (Boolean)saveResultMap.get('success'));
        }
    }

    /**
    *   @description : Test generateTimesheetProof
    **/
    @isTest
    static void test_generateTimesheetProof(){
        Test.startTest();
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(0,[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId =: timesheetsList[0].Id]);
        SIM_TimeApproval.generateTimesheetProof(new List<Id>(new map<Id,sirenum__Timesheet__c>(timesheetsList).keySet()));
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId =: timesheetsList[0].Id]);
    }

    /**
    *   @description : Test updateTimesheetProof
    **/
    @isTest
    static void test_updateTimesheetProof(){
        Test.startTest();
        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, InTimeId__c, InTimeSyncStatus__c, LastIntimeSync__c FROM sirenum__Timesheet__c LIMIT 1];
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Timesheet__c WHERE ProofUploaded__c = true]);
        SIM_TimeApproval.updateTimesheetProof(new List<Id>(new map<Id,sirenum__Timesheet__c>(timesheetsList).keySet()));
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Timesheet__c WHERE ProofUploaded__c = true]);
    }
}