/**
* @description Trigger handler for Rate Modifiers
**/
public with sharing class RateModifierTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after insert trigger event
	**/
	public override void afterInsert() {
        RateModifierHelper.manageRateModifiers((List<sirenum__Rate_Modifier__c>)Trigger.new, null);
	}

    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterUpdate() {
        RateModifierHelper.manageRateModifiers((List<sirenum__Rate_Modifier__c>)Trigger.new, (Map<Id, sirenum__Rate_Modifier__c>)Trigger.oldMap);
	}
}