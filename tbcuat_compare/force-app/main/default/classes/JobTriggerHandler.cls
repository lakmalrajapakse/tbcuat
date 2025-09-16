/**
* @description Trigger handler for jobs 
**/
public with sharing class JobTriggerHandler extends TriggerHandler{

    private static final String JOB_OBJECT_API_NAME = TR1__Job__c.SObjectType.getDescribe().getName();

    
    /**
	* @description Function to handle the after update  trigger event
	**/
    public override void afterInsert() {
        SharingHelper.manageSharing(
            JOB_OBJECT_API_NAME,
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
    }
    
    /**
	* @description Function to handle the after update  trigger event
	**/
    public override void afterUpdate() {
        SharingHelper.manageSharing(
            JOB_OBJECT_API_NAME,
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
    }
}