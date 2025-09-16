trigger AdditionalClientEmail on Additional_Client_Email__c (after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
	new AdditionalClientEmailTriggerHandler().run();
}