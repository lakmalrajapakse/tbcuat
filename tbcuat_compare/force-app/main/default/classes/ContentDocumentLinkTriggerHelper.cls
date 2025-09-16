/**
* @description Helper class for Content Document Link Trigger
**/
public with sharing class ContentDocumentLinkTriggerHelper {
    
    /**
    * @description Method to manage content documents for timesheets
    **/
    public static void manageContentDocumentsForTimesheets(List<ContentDocumentLink> contentDocumentLinksList) {
        Set<Id> timesheetIds = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinksList) {
            if (contentDocumentLink.LinkedEntityId.getSObjectType().getDescribe().getName() == sirenum__Timesheet__c.sObjectType.getDescribe().getName()) {
                timesheetIds.add(contentDocumentLink.LinkedEntityId);
            }
        }
        if (!timesheetIds.isEmpty()) {
            List<InTimeSyncItem__c> intimeSyncItemsToCreate = new List<InTimeSyncItem__c>();
            List<sirenum__Timesheet__c> timesheetsList = [SELECT Id FROM sirenum__Timesheet__c WHERE Id IN: timesheetIds AND IntimeId__c != null];
            Map<String, Set<String>> recordIdsByObjectNameMap = IntimeSyncHelper.getIntimeSyncItemsInQueue(new Set<String>{sirenum__Timesheet__c.sObjectType.getDescribe().getName()});
            for (sirenum__Timesheet__c timesheet : timesheetsList) { 
                if (!recordIdsByObjectNameMap.containsKey(sirenum__Timesheet__c.sObjectType.getDescribe().getName()) || 
                    (recordIdsByObjectNameMap.containsKey(sirenum__Timesheet__c.sObjectType.getDescribe().getName()) 
                        && !recordIdsByObjectNameMap.get(sirenum__Timesheet__c.sObjectType.getDescribe().getName()).contains(timesheet.Id))) {
                    intimeSyncItemsToCreate.add(new InTimeSyncItem__c(
                        Timesheet__c = timesheet.Id,
                        Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED,
                        Type__c = IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET_FILE
                    ));
                }
            }
            if (!intimeSyncItemsToCreate.isEmpty()) {
                insert intimeSyncItemsToCreate;
                if (IntimeSyncHelper.IsInTimeBatchRunning() && !Test.isRunningTest()) {
                    IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
                }
            } 
        }
    }
}