@isTest
public class ProcessJobShift_test {
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
        contactsList[0].Plan_Code__c = picklistLibrariesList[0].Id;        
        contactsList[0].TR1__Candidate_Status__c = 'Registered';
        insert contactsList;

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

        sirenum__WorkSchedule__c ws = new sirenum__WorkSchedule__c(
            Name = 'Test',
            sirenum__Length__c = 7,
            sirenum__Account__c = accountsList[0].Id
        );

        insert ws;

        List<sirenum__WorkScheduleDay__c> wsd = new List<sirenum__WorkScheduleDay__c> {
            new sirenum__WorkScheduleDay__c(sirenum__WorkSchedule__c = ws.Id, sirenum__Offset__c = 0, sirenum__End__c = Time.newInstance(17, 0 ,0, 0), sirenum__Start__c = Time.newInstance(8, 0 ,0, 0)),
            new sirenum__WorkScheduleDay__c(sirenum__WorkSchedule__c = ws.Id, sirenum__Offset__c = 1, sirenum__End__c = Time.newInstance(17, 0 ,0, 0), sirenum__Start__c = Time.newInstance(8, 0 ,0, 0))
        };
        
        insert wsd;

        // create jobs 
        List<TR1__Job__c> jobsList = TestDataCreator.createJobs(
            1,
            accountsList[0].Id,
            picklistLibrariesList[0].Id
        );
        jobsList[0].s5m__AutoFulfil__c = true;
        jobsList[0].s5m__ShiftDemandGeneration__c = 'Ongoing';
        jobsList[0].TR1__Estimated_End_Date__c = null;
        jobsList[0].PPE_Required__c = TR1__Job__c.PPE_Required__c.getDescribe().getPicklistValues().get(0).getValue();
        jobsList[0].H_S_Safety_Risks__c = 'N/A';
        jobsList[0].Risk_Mitigations__c = 'N/A';
        jobsList[0].s5m__JobRole__c = jobRolesList[0].Id;
        jobsList[0].s5m__WorkSchedule__c = ws.Id;

        insert jobsList;
    }
    
    @isTest
    static void testSchedulerExecutesBatch() {
        // Start test context
        Test.startTest();

        // Schedule the job to run 1 minute from now
        String cronExpr = '0 0 1 * * ?';
        String jobId = System.schedule('Test Scheduler', cronExpr, new ProcessJobShiftScheduler());

        // End test context - triggers execution
        Test.stopTest();

        // Assert that the scheduled job has been enqueued
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression);        
    }


        @isTest
    static void testBatch() {        
        Test.startTest();
           
        Database.executeBatch(new ProcessJobShiftBatch('test job'));
        
        Test.stopTest();   
        
        List<TR1__Job__c> jobs = [Select s5m__GenerationLastRequired__c from TR1__Job__c];
        
        System.assertEquals(1, jobs.size());
        System.assertEquals(true, jobs[0].s5m__GenerationLastRequired__c != null);
    }
}