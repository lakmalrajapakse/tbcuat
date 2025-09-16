@isTest
public without sharing class SIM_ManualTimesheetGenerationTest {
    static String DEFAULT_TEMPLATE = 'Default_Timesheet_Generation_Template';

    static Account acc;
    static Contact con;
    static Contact clientContact;
    static sirenum__ProActiveContract__c contract;
    static sirenum__Site__c site;
    static sirenum__Team__c team;
    static DateTime testDateTime;
    static Date testDate;
    static List<sirenum__Shift__c> testShifts;
    static sirenum__Payroll_Cycle__c payrollCycle;
    static sirenum__Week__c period;     

    static void createTestData(){
        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        invoiceTermsList[0].TimesheetsOnInvoices__c = InvoiceTerm__c.TimesheetsOnInvoices__c.getDescribe().getPicklistValues().get(0).getValue();
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

        acc = SIM_TestDataFactory.genTestAccount('Candidate Pool', 'Candidate Pool', false);
        acc.TR1__Status__c = 'Onboarded';
        acc.InvoiceTerm__c = invoiceTermsList[0].Id;        
        
        insert acc;

        Id candidateRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Candidate').getRecordTypeId();
        Id clientRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        con = new Contact(FirstName = 'tot', LastName = 'brown', AccountId = acc.Id, RecordTypeId = candidateRT,  email='abc@abc.com');
        con.InTimeExternalId__c = 'extId1';
        con.TR1__Candidate_Status__c = 'Registered';
        con.Do_you_have_the_right_to_work_in_the_UK__c = true;
        con.Do_you_currently_live_in_the_UK__c = true;
        con.Plan_Code__c = picklistLibrariesList[0].Id;

        clientContact = new Contact(FirstName = 'Ridge2', LastName = 'grwon', AccountId = acc.Id, RecordTypeId = clientRT, email='abc@abc.com');

        insert new List<Contact> {con, clientContact};
        
        site = SIM_TestDataFactory.genTestSite(acc, true);

        contract = SIM_TestDataFactory.genTestContract(acc, clientContact, acc, false);
        contract.Manual_Timesheet_Generation__c = true;
        insert contract;

        team = SIM_TestDataFactory.genTestJobRole(contract, false);
        team.sirenum__AWR_Group__c= sirenum__Team__c.sirenum__AWR_Group__c.getDescribe().getPicklistValues().get(0).getValue();
        List<Account> accountsList = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        team.Name = accountsList[0].Client_Code__c+' - Test Driver';        
        insert team;
        
        payrollCycle = SIM_TestDataFactory.getTestCycle('Monday - Sunday');
        insert payrollCycle;

        period = SIM_TestDataFactory.getTestPeriod(payrollCycle.id, system.today().toStartOfWeek());
        insert period;

        testDateTime = dateTime.newInstance(system.today().toStartOfWeek().addDays(2), Time.newInstance(9,0,0,0));
        testDate = system.today().toStartOfWeek().addDays(2);

        testShifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime,
                sirenum__Scheduled_End_Time__c = testDateTime.addHours(1),
                sirenum__Published__c = true,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1,
                Approved__c = true
            ),
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(1),
                sirenum__Published__c = true,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1
            )
        };

        insert testShifts;                
    }
    
    @isTest
    static void test_getTemplate() {
        createTestData();
        Test.startTest();
        String results = SIM_ManualTimesheetGenerationController.getUploadTemplates();
        Test.stopTest();

        List<SIM_Option> response= (List<SIM_Option>) JSON.deserialize(results, Type.forName('List<SIM_Option>'));
        system.assert(response.size() > 0);

    }

        @isTest
    static void test_getCycle() {
        createTestData();
        Test.startTest();
        List<SIM_LookupSearchResult> results = SIM_ManualTimesheetGenerationController.searchPayCycles('Mon', null);
        Test.stopTest();
                
        system.assert(results.size() > 0);
    }

    @isTest
    static void test_getPeriods() {
        createTestData();
        List<SIM_LookupSearchResult> results = SIM_ManualTimesheetGenerationController.searchPeriods(system.today().toStartOfWeek().format(), new List<String>{payrollCycle.Id});        
    }

    @isTest
    static void testRecentlyViewedCycles() {
        List<SIM_LookupSearchResult> recent = SIM_ManualTimesheetGenerationController.getRecentlyViewedPayCycles();        
    }

    @isTest
    static void test_loadTemplate1() {        
        createTestData();                

        Test.startTest();
        String sheetData = '{"Sheet1": ['      
                                    + '{"Shift ID": "' + testShifts[0].id + '","Rate Type": "Normal","Pay Rate": "10.00","Charge Rate": "17.00","Hours": "8","inTime Pay Element":"NORMAL","__ROW_NUMBER__": 2},'
                                    + '{"Shift ID": "' + testShifts[0].id + '","Rate Type": "Overtime","Pay Rate": "","Charge Rate": "","Hours": "0","inTime Pay Element":"NORMAL","__ROW_NUMBER__": 3}'
                                    +']}';
        String results = SIM_ManualTimesheetGenerationController.loadData(DEFAULT_TEMPLATE, 'test.csv', 1, 2, period.id, sheetData);        
        Test.stopTest();

        List<Manual_Timesheet_Generation_Error__c> errors = [select id, error_message__c from Manual_Timesheet_Generation_Error__c ];        
        system.assertEquals(0, errors.size());        
        
        List<sirenum__Shift__c> shifts = [select id from sirenum__Shift__c where sirenum__Timesheet_summaries__c != null];
        system.assertEquals(1, shifts.size());

        List<sirenum__Timesheet_Line__c> tsl = [select id from sirenum__Timesheet_Line__c];
        system.assertEquals(1, tsl.size());

        List<Manual_Timesheet_Generation__c> upload = [select id, status__C from Manual_Timesheet_Generation__c];
        system.assertEquals(1, upload.size());
        system.assertEquals(SIM_ManualTimesheetGeneration.UPLOAD_SUCCESS_STATUS, upload[0].status__C);
        
        String response = SIM_ManualTimesheetGenerationController.getBatchProgress(upload[0].id);
        SIM_Response.Response r = SIM_TestDataFactory.deserializeSIMResponse(response, Type.forName('SIM_ShiftUploadController.StatusInfo'), null);
        System.assertEquals(false, ((SIM_ShiftUploadController.StatusInfo) r.responseObject).isErrored);
    }

    @isTest
    static void test_loadTemplateNeg() {        
        createTestData();

        Test.startTest();
        String sheetData = '{"Sheet1": [' +     
                                    '{}]}';
        String results = SIM_ManualTimesheetGenerationController.loadData(DEFAULT_TEMPLATE, 'test.csv', 1, 2, period.id, sheetData);
        Test.stopTest();

        SIM_Response.Response response= SIM_TestDataFactory.deserializeSIMResponse(results, null, null);
        system.assertEquals(true, response.success);

        List<Manual_Timesheet_Generation__c> upload = [select id, status__C from Manual_Timesheet_Generation__c];
        system.assertEquals(1, upload.size());
        system.assertEquals(SIM_ShiftUploader.UPLOAD_FAIL_STATUS, upload[0].status__C);   
    }

  /*  
    @isTest
    static void test_loadTemplate2() {        
        createTestData();

        List<Shift_Upload_Template__mdt> templates = [select RecordID__c, Billable_Hours__c, Billable_Start_Date__c, 
                                                    Billable_Start_Time__c, Billable_End_Time__c, Date_Format__c,
                                                    Is_Approved__c,
                                                    Job_Role__c, Payroll_ID__c, PO_Number__c, Site__c,
                                                    Shift_Date__c, Job_Role_Id__c, 
                                                    Site_Id__c, Actual_Start_Time__c, Actual_End_Time__c, Actual_Start_Date__c
                                                    from Shift_Upload_Template__mdt where DeveloperName = :DEFAULT_TEMPLATE];
        System.assertEquals(1, templates.size());
        templates[0].RecordID__c = null;
        templates[0].Payroll_ID__c='Payroll Id';
        templates[0].Shift_Date__c='Date';
        templates[0].Job_Role_Id__c='Job Role';
        templates[0].Site_Id__c='Site';        
        templates[0].Site__c=null;
        templates[0].Job_Role__c=null;
        templates[0].Billable_Start_Date__c=null;
        templates[0].Billable_Start_Time__c=null;
        templates[0].Billable_End_Time__c=null;
        templates[0].Billable_Hours__c='Hours';
        templates[0].PO_Number__c='PO Number';
        templates[0].Is_Approved__c='Is Approved';
        templates[0].Actual_Start_Time__c= 'Actual Start Time';
        templates[0].Actual_End_Time__c = 'Actual End Time';
        templates[0].Actual_Start_Date__c = null;
    
    
        Test.startTest();        
        SIM_ShiftUploader uploader = new SIM_ShiftUploader('test.csv', DEFAULT_TEMPLATE, 1, 2);
        uploader.setHeaderMappings(templates[0]);
        
        String sheetData = '{"Sheet1": [' +     
                                    '{"Payroll Id": "extId1","Date": "14/02/2024","Job Role": "' + team.id + '","Site": "' + site.id + '","Hours": "7","PO Number": "PO-123","Is Approved": "FALSE","Actual Start Time": "10:00","Actual End Time": "17:00","__ROW_NUMBER__": 2}]}';
        
        Id batchProcessId = uploader.submitBatch(sheetData);
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [select id from sirenum__Shift__c where sirenum__Billable_Start_Time__c != null];
        system.assertEquals(1, shifts.size());

        List<Bulk_Shift_Upload__c> upload = [select status__C from Bulk_Shift_Upload__c];
        system.assertEquals(1, upload.size());
        system.assertEquals(SIM_ShiftUploader.UPLOAD_SUCCESS_STATUS, upload[0].status__C);

        String response = SIM_ShiftUploadController.getBatchProgress(batchProcessId);
        SIM_Response.Response r = SIM_TestDataFactory.deserializeSIMResponse(response, Type.forName('SIM_ShiftUploadController.StatusInfo'), null);
        System.assertEquals(false, ((SIM_ShiftUploadController.StatusInfo) r.responseObject).isErrored);
    }

    @isTest
    static void test_loadTemplate2Neg() {        
        createTestData();

        List<Shift_Upload_Template__mdt> templates = [select RecordID__c, Billable_Hours__c, Billable_Start_Date__c, 
                                                    Billable_Start_Time__c, Billable_End_Time__c, Date_Format__c,
                                                    Is_Approved__c,
                                                    Job_Role__c, Payroll_ID__c, PO_Number__c, Site__c,
                                                    Shift_Date__c, Job_Role_Id__c, 
                                                    Site_Id__c, Actual_Start_Time__c, Actual_End_Time__c, Actual_Start_Date__c
                                                    from Shift_Upload_Template__mdt where DeveloperName = :DEFAULT_TEMPLATE];
        System.assertEquals(1, templates.size());
        templates[0].RecordID__c = null;
        templates[0].Payroll_ID__c='Payroll Id';
        templates[0].Shift_Date__c='Date';
        templates[0].Job_Role_Id__c='Job Role';
        templates[0].Site_Id__c='Site';        
        templates[0].Site__c=null;
        templates[0].Job_Role__c=null;
        templates[0].Billable_Start_Date__c=null;
        templates[0].Billable_Start_Time__c=null;
        templates[0].Billable_End_Time__c=null;
        templates[0].Billable_Hours__c='Hours';
        templates[0].PO_Number__c='PO Number';
        templates[0].Is_Approved__c='Is Approved';
        templates[0].Actual_Start_Time__c= null;
        templates[0].Actual_End_Time__c = null;
        templates[0].Actual_Start_Date__c = null;
    
        
        
        Test.startTest();        
        SIM_ShiftUploader uploader = new SIM_ShiftUploader('test.csv', DEFAULT_TEMPLATE, 1, 2);
        uploader.setHeaderMappings(templates[0]);
        
        String sheetData = '{"Sheet1": [' +     
                                    '{}]}';
        
        Id batchProcessId = uploader.submitBatch(sheetData);
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [select id from sirenum__Shift__c where sirenum__Billable_Start_Time__c != null];
        system.assertEquals(0, shifts.size());

        List<Bulk_Shift_Upload__c> upload = [select status__C from Bulk_Shift_Upload__c];
        system.assertEquals(1, upload.size());
        system.assertEquals(SIM_ShiftUploader.UPLOAD_FAIL_STATUS, upload[0].status__C);

        String response = SIM_ShiftUploadController.getBatchProgress(batchProcessId);
        SIM_Response.Response r = SIM_TestDataFactory.deserializeSIMResponse(response, Type.forName('SIM_ShiftUploadController.StatusInfo'), null);
        System.assertEquals(true, ((SIM_ShiftUploadController.StatusInfo) r.responseObject).isErrored);
    }

    
    @isTest
    static void test_loadTemplate3() {        
        createTestData();

        List<Shift_Upload_Template__mdt> templates = [select RecordID__c, Billable_Hours__c, Billable_Start_Date__c, 
                                                    Billable_Start_Time__c, Billable_End_Time__c, Date_Format__c,
                                                    Is_Approved__c,
                                                    Job_Role__c, Payroll_ID__c, PO_Number__c, Site__c,
                                                    Shift_Date__c, Job_Role_Id__c, 
                                                    Site_Id__c, Actual_Start_Time__c, Actual_End_Time__c, Actual_Start_Date__c
                                                    from Shift_Upload_Template__mdt where DeveloperName = :DEFAULT_TEMPLATE];
        System.assertEquals(1, templates.size());
        templates[0].RecordID__c = null;
        templates[0].Payroll_ID__c='Payroll Id';
        templates[0].Shift_Date__c='Date';
        templates[0].Job_Role_Id__c=null;
        templates[0].Site_Id__c=null;        
        templates[0].Site__c='Site';
        templates[0].Job_Role__c='Job Role';
        templates[0].Billable_Start_Date__c=null;
        templates[0].Billable_Start_Time__c=null;
        templates[0].Billable_End_Time__c=null;
        templates[0].Billable_Hours__c='Hours';
        templates[0].PO_Number__c='PO Number';
        templates[0].Is_Approved__c='Is Approved';
        templates[0].Actual_Start_Time__c= null;
        templates[0].Actual_End_Time__c = null;
        templates[0].Actual_Start_Date__c = null;

        List<sirenum__Site__c> sites = [select id, name from sirenum__Site__c where id = :site.id];

        Test.startTest();        
        SIM_ShiftUploader uploader = new SIM_ShiftUploader('test.csv', DEFAULT_TEMPLATE, 1, 2);
        uploader.setHeaderMappings(templates[0]);        

        String sheetData = '{"Sheet1": [' +     
                                    '{"Payroll Id": "extId1","Date": "14/02/2024","Job Role": "' + team.name + '","Site": "' + sites[0].name + '","Hours": "7","PO Number": "PO-123","Is Approved": "FALSE","__ROW_NUMBER__": 2}]}';
        
        Id batchProcessId = uploader.submitBatch(sheetData);
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [select id from sirenum__Shift__c where sirenum__Billable_Start_Time__c != null];
        system.assertEquals(1, shifts.size());

        List<Bulk_Shift_Upload__c> upload = [select id, status__C from Bulk_Shift_Upload__c];
        system.assertEquals(1, upload.size());
        system.assertEquals(SIM_ShiftUploader.UPLOAD_SUCCESS_STATUS, upload[0].status__C);

        String response = SIM_ShiftUploadController.getBatchProgress(batchProcessId);
        SIM_Response.Response r = SIM_TestDataFactory.deserializeSIMResponse(response, Type.forName('SIM_ShiftUploadController.StatusInfo'), null);
        System.assertEquals(false, ((SIM_ShiftUploadController.StatusInfo) r.responseObject).isErrored);

        //change status to processing
        upload[0].Status__c = SIM_ShiftUploader.UPLOAD_LOADING_STATUS;
        update upload[0];
        response = SIM_ShiftUploadController.getBatchProgress(batchProcessId);
        r = SIM_TestDataFactory.deserializeSIMResponse(response, Type.forName('SIM_ShiftUploadController.StatusInfo'), null);
        System.assertEquals(false, ((SIM_ShiftUploadController.StatusInfo) r.responseObject).isErrored);
    }


    @isTest
    static void test_utilsCover() {        
        createTestData();
        SIM_SObjResults r = new SIM_SObjResults(new List<String> {'sirenum__Contact__r.name'}, [select sirenum__Contact__r.name, id
           from sirenum__Shift__c
           ]);
        
        system.assertEquals(2, r.getIds().size());
    }
*/
}