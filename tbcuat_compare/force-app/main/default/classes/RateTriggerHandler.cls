/**
* @description Trigger handler for rate
**/
public with sharing class RateTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
		SharingHelper.manageSharing(
            TR1__Rate__c.sObjectType.getDescribe().getName(),
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
            TR1__Rate__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}