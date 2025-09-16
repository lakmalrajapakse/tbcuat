/**
* @description Trigger handler for Contact
**/
public with sharing class ContactTriggerHandler extends TriggerHandler{

    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterInsert() {
        SharingHelper.manageSharing(
            Contact.sObjectType.getDescribe().getName(),
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
	}
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        IntimeSyncHelper.validateAndCreateIntimeSyncItems(
            Contact.sObjectType.getDescribe().getName(),
            InTimeSyncItem__c.Person__c.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap
        );
        SharingHelper.manageSharing(
            Contact.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}