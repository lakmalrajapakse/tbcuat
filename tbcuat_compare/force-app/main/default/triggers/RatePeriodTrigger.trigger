trigger RatePeriodTrigger on TR1__RatePeriod__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new RatePeriodTriggerHandler().run();
}