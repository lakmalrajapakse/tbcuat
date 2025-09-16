trigger JobRoleTrigger on sirenum__Team__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    system.debug('SIMON JobRoleTrigger TRIGGER');
    new JobRoleTriggerHandler().run();
}