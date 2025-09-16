/**
* @description Trigger handler for timesheet line
**/
public with sharing class TimesheetLineTriggerHandler extends TriggerHandler{

    /**
	* @description Function to handle the before insert  trigger event
	**/
	public override void beforeInsert() {
        TimesheetLineHelper.manageTimesheetLines((List<sirenum__Timesheet_Line__c>)Trigger.new,null);
		TimesheetLineHelper.manageIntimeRateMappings((List<sirenum__Timesheet_Line__c>)Trigger.new);
	}
    
    /**
	* @description Function to handle the before update  trigger event
	**/
	public override void beforeUpdate() {
        TimesheetLineHelper.manageTimesheetLines((List<sirenum__Timesheet_Line__c>)Trigger.new,(Map<Id, sirenum__Timesheet_Line__c>)Trigger.oldMap);
		TimesheetLineHelper.manageIntimeRateMappings((List<sirenum__Timesheet_Line__c>)Trigger.new);
	}
}