/**
* @description Trigger handler for Account
**/
public with sharing class AccountTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterInsert() {
        SharingHelper.manageSharing(
            Account.sObjectType.getDescribe().getName(),
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
            Account.sObjectType.getDescribe().getName(),
            InTimeSyncItem__c.Client__c.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap
        );
        SharingHelper.manageSharing(
            Account.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}