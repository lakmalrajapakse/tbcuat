/**
* @description Trigger handler for Leads
**/
public with sharing class LeadTriggerHandler extends TriggerHandler{
    
     /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
		SharingHelper.manageSharing(
            Lead__c.sObjectType.getDescribe().getName(),
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
            Lead__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}