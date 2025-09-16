global without sharing class ArchiveEmailAttachmentSchedule implements Schedulable {
    

    global void execute(SchedulableContext sc) {
        TBC_General_Settings__c settings = TBC_General_Settings__c.getInstance();
        Integer batchSize = settings.Delete_Email_Attachment_Batch_Size__c != null ? (Integer) settings.Delete_Email_Attachment_Batch_Size__c : 50;        
     
        Database.executeBatch(new ArchiveEmailAttachmentBatch(), batchSize);
    }    

}