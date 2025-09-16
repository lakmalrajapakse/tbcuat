trigger InvoiceTerm on InvoiceTerm__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
	new InvoiceTermTriggerHandler().run();
}