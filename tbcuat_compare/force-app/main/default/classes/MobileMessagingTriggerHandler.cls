/**
* @description Trigger handler for mobile messaging
**/
public with sharing class MobileMessagingTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
		SharingHelper.manageSharing(
            MobileMessaging_SMS_Message__c.sObjectType.getDescribe().getName(),
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
            MobileMessaging_SMS_Message__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
    }
}