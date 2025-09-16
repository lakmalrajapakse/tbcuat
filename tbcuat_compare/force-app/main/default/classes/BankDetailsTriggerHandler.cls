/**
* @description Trigger handler for Bank Account
**/
public with sharing class BankDetailsTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        IntimeSyncHelper.validateAndCreateIntimeSyncItemsForParentRecords(
            Bank_Details__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap
        );
	}
}