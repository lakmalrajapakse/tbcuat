/**
* @description Test class for Intime Sync Scheduler
**/
@isTest(seeAllData=false)
private with sharing class IntimeSyncSchedulerTest {
    
    /**
    * @description Test IntimeSyncScheduler
    **/
    @isTest
    static void test_IntimeSyncScheduler() {
        Test.startTest();
        String jobId = System.schedule (
            'testBasicScheduledApex',
            '0 0 0 3 9 ? 2040',
            new IntimeSyncScheduler()
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