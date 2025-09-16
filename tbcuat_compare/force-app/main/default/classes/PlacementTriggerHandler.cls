/**
* @description Trigger handler for Placement
**/
public with sharing class PlacementTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        IntimeSyncHelper.validateAndCreateIntimeSyncItems(
            sirenum__Placement__c.sObjectType.getDescribe().getName(),
            InTimeSyncItem__c.Placement__c.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap
        );
	}
}