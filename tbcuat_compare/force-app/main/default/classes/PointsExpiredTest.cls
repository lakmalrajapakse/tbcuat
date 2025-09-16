@isTest
public class PointsExpiredTest {

    @testSetup
    static void setupData() {
        Id planCodeRecordTypeId =  Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByName().get('Plan Code').getRecordTypeId();
        Picklist_Library__c pl= new Picklist_Library__c(Davis_Deparment_Id__c = '5343',recordTypeId=planCodeRecordTypeId);
        insert pl;

        // Create Contact that matches batch query criteria
        Contact c = new Contact(
            FirstName = 'Batch',
            LastName = 'Driver',
            Davis_Id__c = '123456',
            Davis_Status__c = 'Active',
            Next_Check_Date__c = Date.today().addDays(-1), // Should be picked up
            Plan_Code__c = pl.Id,
            TR1__Candidate_Status__c = 'Application'
        );
        insert c;

        sirenum__TicketType__c offenceCode = new sirenum__TicketType__c(
            Name = 'SP30',
            external_id__c = '5434',
            Offence_Code__c ='SP30'
        );
        insert offenceCode;

        Sirenum__Ticket__c ticket =  new Sirenum__Ticket__c(
            sirenum__Owner__c = c.Id,
            sirenum__TicketType__c = offenceCode.Id,
            sirenum__Valid_from__c = Date.today().addDays(-5),
            sirenum__Valid_until__c = Date.today().addDays(5),
            Commenced_date__c = Date.today().AddDays(-5),
            Offence_Date__c = Date.today().AddDays(-5),
            Points__c = 3
        );
        insert ticket;

        ticket.sirenum__Revoked__c =false;
        update ticket;

    }

    @isTest
    static void testSchedulerExecutesBatch() {
        // Start test context
        Test.startTest();

        // Schedule the job to run 1 minute from now
        String cronExpr = '0 0 1 * * ?';
        String jobId = System.schedule('Test Scheduler', cronExpr, new PointsExpiredSchedule());

        // End test context - triggers execution
        Test.stopTest();

        // Assert that the scheduled job has been enqueued
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression);        
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();

        PointsExpiredBatch batch = new PointsExpiredBatch();
        Database.executeBatch(batch);

        Test.stopTest();
    }
}