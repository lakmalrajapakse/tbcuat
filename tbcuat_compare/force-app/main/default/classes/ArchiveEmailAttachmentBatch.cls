public without sharing class ArchiveEmailAttachmentBatch implements Database.Batchable<SObject> {
    static final TBC_General_Settings__c settings = TBC_General_Settings__c.getInstance();

    public Database.QueryLocator start(Database.BatchableContext bc) {        
        return Database.getQueryLocator(
            [select id, linkedEntity.type, SystemModstamp, ContentDocument.title, linkedentityid from ContentDocumentLink where ContentDocumentId in (
             select ContentDocumentId from contentversion where Delete_Email_Attachment_Link__c = TRUE)
             order by LinkedEntityId]
        );
    }    
    
    public void execute(Database.BatchableContext bc, List<ContentDocumentLink> scope) {
        List<ContentDocumentLink> toDelete = new List<ContentDocumentLink>();
        
        Set<Id> emailIds = new Set<Id>();
        DateTime archiveDate = System.now().addDays(Integer.valueOf(((settings.Delete_Email_Attachment_Links_days__c == null) ? 50 : settings.Delete_Email_Attachment_Links_days__c))  * -1);

        for (ContentDocumentLink scopeItem : scope) {
            if (scopeItem.LinkedEntity.Type == 'EmailMessage' && scopeItem.SystemModstamp <= archiveDate) {
                toDelete.add(scopeItem);
                emailIds.add(scopeItem.LinkedEntityId);                
            }
        }

        if (toDelete.isEmpty()) {
            return;
        }

        Map<Id, EmailMessage> toUpdate = new Map<Id, EmailMessage>([select id, TR1__AttachmentNames__c from EmailMessage where id in :emailIds]);
        for (ContentDocumentLink deleteItem : toDelete) {
            if (toUpdate.containsKey(deleteItem.LinkedEntityId)) {
                toUpdate.get(deleteItem.LinkedEntityId).TR1__AttachmentNames__c = (toUpdate.get(deleteItem.LinkedEntityId).TR1__AttachmentNames__c == null) ? deleteItem.ContentDocument.Title : toUpdate.get(deleteItem.LinkedEntityId).TR1__AttachmentNames__c + '; ' + deleteItem.ContentDocument.Title;
            }
        }

        update toUpdate.values();
        delete toDelete;
    }

    // Description: Batch finish method
    public void finish(Database.BatchableContext bc) {                
    }
}