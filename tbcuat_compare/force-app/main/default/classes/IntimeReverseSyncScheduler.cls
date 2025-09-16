/**
* @description Scheduler used to fetch the modified intime sync items
**/
global with sharing class IntimeReverseSyncScheduler implements Schedulable,Database.AllowsCallouts{
    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {
        if (!Test.isRunningTest()) Database.executeBatch(new IntimeReverseSyncBatch(1),1);
    }
}