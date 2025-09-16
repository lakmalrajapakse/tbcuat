/**
* @description Trigger handler for Expenses
**/
public with sharing class ExpenseTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after insert trigger event
	**/
	public override void afterInsert() {
        ExpenseHelper.manageExpenses((List<sirenum__Expense__c>)Trigger.new, null);
		SharingHelper.manageSharing(
            sirenum__Expense__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            null,
            SharingHelper.TriggerContext.RECORDCREATE
        );
	}

    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterUpdate() {
        ExpenseHelper.manageExpenses((List<sirenum__Expense__c>)Trigger.new, (Map<Id, sirenum__Expense__c>)Trigger.oldMap);
		SharingHelper.manageSharing(
            sirenum__Expense__c.sObjectType.getDescribe().getName(),
            Trigger.new,
            Trigger.oldMap,
            SharingHelper.TriggerContext.RECORDUPDATE
        );
	}

    /**
	* @description Function to handle the after delete trigger event
	**/
	public override void afterDelete() {
        ExpenseHelper.manageExpenses(null, (Map<Id, sirenum__Expense__c>)Trigger.oldMap);
	}
}