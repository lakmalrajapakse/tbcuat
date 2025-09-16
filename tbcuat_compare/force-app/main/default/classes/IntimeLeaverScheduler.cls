/**
* @description Scheduler used to sync leaver information in time
**/
global with sharing class IntimeLeaverScheduler implements Schedulable,Database.AllowsCallouts{
    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {
        if (!Test.isRunningTest()) Database.executeBatch(new IntimeLeaverSyncBatch(),1);
    }
}