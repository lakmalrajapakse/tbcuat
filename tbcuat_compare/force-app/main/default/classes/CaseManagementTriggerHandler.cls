/**
* @description Trigger handler for case management log
**/
public with sharing class CaseManagementTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
		SharingHelper.manageSharing(
            CaseManagement__c.sObjectType.getDescribe().getName(),
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
            CaseManagement__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}