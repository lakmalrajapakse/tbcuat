/**
* @description Test class for Intime Reverse Sync Scheduler
**/
@isTest(seeAllData=false)
private with sharing class IntimeReverseSyncSchedulerTest {
    
    /**
    * @description Test IntimeReverseSyncScheduler
    **/
    @isTest
    static void test_IntimeReverseSyncScheduler() {
        Test.startTest();
        String jobId = System.schedule (
            'testBasicScheduledApex',
            '0 0 0 3 9 ? 2040',
            new IntimeReverseSyncScheduler()
        );
        Test.stopTest();
        // Get the information from the CronTrigger API object
        CronTrigger cronTrigger = 
            [SELECT 
                Id, 
                CronExpression, 
                TimesTriggered, 
                NextFireTime
            FROM CronTrigger 
            WHERE id = :jobId];
        // Verify the expressions are the same
        Assert.areEqual('0 0 0 3 9 ? 2040',cronTrigger.CronExpression);
    }
}