trigger JobLeadTrigger on TR1__Job_Leads__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    system.debug('SIMON JobLeadTrigger TRIGGER');
    new JobLeadTriggerHandler().run();
}