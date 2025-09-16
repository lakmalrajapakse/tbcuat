trigger DeletedShiftTrigger on sirenum__Deleted_Shift__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new DeletedShiftTriggerHandler().run();
}