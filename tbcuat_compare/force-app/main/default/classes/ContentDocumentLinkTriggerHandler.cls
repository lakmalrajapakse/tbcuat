/**
* @description : Trigger Handler for Content Document Link  
**/
public with sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler{
    /**
	* @description Method to handle after insert trigger event
	**/
    public override void afterInsert() {
        ContentDocumentLinkTriggerHelper.manageContentDocumentsForTimesheets((List<ContentDocumentLink>)Trigger.new);
	}
}