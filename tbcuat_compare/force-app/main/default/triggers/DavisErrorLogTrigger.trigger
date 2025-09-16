trigger DavisErrorLogTrigger on Davis_Error_Log__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new DavisErrorLogTriggerHandler().run();
}