/**
* @description Trigger handler for rate card 
**/
public with sharing class RateCardTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
		SharingHelper.manageSharing(
            sirenum__Rate_Card__c.sObjectType.getDescribe().getName(),
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
            sirenum__Rate_Card__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}