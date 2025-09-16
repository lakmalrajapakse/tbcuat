trigger RelatedJobTrigger on TR1__Related_Job__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new RelatedJobTriggerHandler().run();
}