/**
* @description Trigger handler for Invoice Term
**/
public with sharing class InvoiceTermTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {
        IntimeSyncHelper.validateAndCreateIntimeSyncItemsForParentRecords(
            InvoiceTerm__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap
        );
	}
}