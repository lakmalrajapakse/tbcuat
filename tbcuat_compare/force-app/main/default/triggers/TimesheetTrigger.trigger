trigger TimesheetTrigger on sirenum__Timesheet__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new TimesheetTriggerHandler().run();
}