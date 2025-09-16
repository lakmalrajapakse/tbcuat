trigger RateTrigger on TR1__Rate__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new RateTriggerHandler().run();
}