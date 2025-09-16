/**
* @description Trigger handler for break definitions
**/
public with sharing class BreakDefinitionTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterInsert() {
        RecalculateShiftBreakBatch.submitBatch(
            Trigger.new
        );

		SharingHelper.manageSharing(
            sirenum__Break_definition__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
	}
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        List <sirenum__Break_definition__c> updatedBreakDefinitions = new List<sirenum__Break_definition__c>();
        updatedBreakDefinitions.addAll((List <sirenum__Break_definition__c>) Trigger.new);
        updatedBreakDefinitions.addAll((List <sirenum__Break_definition__c>) Trigger.old);

        RecalculateShiftBreakBatch.submitBatch(
            updatedBreakDefinitions
        );

		SharingHelper.manageSharing(
            sirenum__Break_definition__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}

    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterDelete() {
		RecalculateShiftBreakBatch.submitBatch(
            Trigger.old
        );
	}
}