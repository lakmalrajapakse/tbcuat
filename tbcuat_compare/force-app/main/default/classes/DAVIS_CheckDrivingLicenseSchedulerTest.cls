@isTest
public class DAVIS_CheckDrivingLicenseSchedulerTest {
    
    @isTest
    static void testSchedulerExecutesBatch() {
        // Start test context
        Test.startTest();

        // Schedule the job to run 1 minute from now
        String cronExpr = '0 0 12 * * ?';
        String jobId = System.schedule('Test DAVIS Scheduler', cronExpr, new DAVIS_CheckDrivingLicenseScheduler());

        // End test context - triggers execution
        Test.stopTest();

        // Assert that the scheduled job has been enqueued
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered, 'Job should not have triggered yet in test context');
    }
}