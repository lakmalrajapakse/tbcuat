/**
* @description Trigger handler for timesheet 
**/
public without sharing class TimesheetTriggerHandler extends TriggerHandler{

	/**
	* @description Function to handle the before update trigger event
	**/
	public override void beforeInsert() {
        TimesheetHelper.calculateIntimeWeeks((List<sirenum__Timesheet__c>)Trigger.new,null);
	}

	/**
	* @description Function to handle the before update trigger event
	**/
	public override void beforeUpdate() {
        TimesheetHelper.validateTimesheetOnUpdate((List<sirenum__Timesheet__c>)Trigger.new,(Map<Id, sirenum__Timesheet__c>)Trigger.oldMap);
		TimesheetHelper.calculateRebates((List<sirenum__Timesheet__c>)Trigger.new);
		TimesheetHelper.calculateIntimeWeeks((List<sirenum__Timesheet__c>)Trigger.new,(Map<Id, sirenum__Timesheet__c>)Trigger.oldMap);
	}
    
    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterUpdate() {
        TimesheetHelper.manageTimesheets((List<sirenum__Timesheet__c>)Trigger.new,(Map<Id, sirenum__Timesheet__c>)Trigger.oldMap);
	}

	/**
	* @description Function to handle the before delete trigger event
	**/
	public override void beforeDelete() {
        TimesheetHelper.validateTimesheetOnDelete((List<sirenum__Timesheet__c>)Trigger.old);
	}
}