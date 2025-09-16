/**
* @description Trigger handler for Account
**/
public without sharing class AdditionalClientEmailTriggerHandler extends TriggerHandler{
    
    /**
	* @description Function to handle the after update trigger event
	**/
	public override void afterInsert() {
        AdditionalClientEmailHelper.manageInvoiceEmailChange(            
            Trigger.new,
            null            
        );
	}

    /**
	* @description Function to handle the after update  trigger event
	**/
	public override void afterUpdate() {        
        AdditionalClientEmailHelper.manageInvoiceEmailChange(                        
            Trigger.new,
            Trigger.oldMap          
        );
	}


    /**
	* @description Function to handle the after delete  trigger event
	**/
	public override void afterDelete() {
        AdditionalClientEmailHelper.manageInvoiceEmailChange(                        
            Trigger.old,
            null
        );    
	}


    /**
	* @description Function to handle the after undelete  trigger event
	**/
	public override void afterUndelete() {
        AdditionalClientEmailHelper.manageInvoiceEmailChange(                        
            Trigger.new,
            null
        );    
	}
}