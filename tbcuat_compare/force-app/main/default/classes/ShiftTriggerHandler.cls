/**
* @description Trigger handler for shifts
**/
public with sharing class ShiftTriggerHandler extends TriggerHandler{

    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
        ShiftHelper.managePlacements((List<sirenum__Shift__c>)Trigger.new);
		
		
		SharingHelper.manageSharing(
            sirenum__Shift__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
	}
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        ShiftHelper.managePlacements((List<sirenum__Shift__c>)Trigger.new);
		
		
		SharingHelper.manageSharing(
            sirenum__Shift__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}
}