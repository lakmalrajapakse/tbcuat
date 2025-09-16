/**
* @description Trigger handler for employee request
**/
public with sharing class EmployeeRequestTriggerHandler extends TriggerHandler{

	/**
	* @description Function to handle the before insert  trigger event
	**/
	public override void beforeInsert() {
        EmployeeRequestHelper.manageEmployeeRequests((List<sirenum__Employee_Request__c>)Trigger.new);
	}

    /**
	* @description Function to handle the after insert  trigger event
	**/
	public override void afterInsert() {
        EmployeeRequestHelper.manageEmployeeRequests((List<sirenum__Employee_Request__c>)Trigger.new,null);
	}

	/**
	* @description Function to handle the before insert  trigger event
	**/
	public override void beforeUpdate() {
        EmployeeRequestHelper.manageEmployeeRequests((List<sirenum__Employee_Request__c>)Trigger.new);
	}
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        EmployeeRequestHelper.manageEmployeeRequests((List<sirenum__Employee_Request__c>)Trigger.new,(Map<Id, sirenum__Employee_Request__c>)Trigger.oldMap);
	}
}