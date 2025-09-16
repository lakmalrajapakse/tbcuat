/**
* @description Apex class to trigger intime sync
**/
public with sharing class TriggerIntimeSyncController {
    
    private Apexpages.standardSetController standardSetController;
    public Boolean triggeredSyncActionSuccessfully {get; set;}

    /** 
    *  @description : Constructor
    **/ 
    public TriggerIntimeSyncController(Apexpages.standardSetController standardSetController){
        this.standardSetController = standardSetController;
        this.triggeredSyncActionSuccessfully = false;
    }

    /** 
    *  @description : Redirect to trigger the sync
    **/ 
    public PageReference triggerSync() {
        try{
            List<InTimeSyncItem__c> selectedIntimeSyncItemsList = (List<InTimeSyncItem__c>)this.standardSetController.getSelected();
            List<InTimeSyncItem__c> intimeSyncItemsList = [SELECT Id, Status__c FROM InTimeSyncItem__c WHERE Id IN: selectedIntimeSyncItemsList AND Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED];
            for (InTimeSyncItem__c intimeSyncItem : intimeSyncItemsList) {
                intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED;
            }
            if (!intimeSyncItemsList.isEmpty()) update intimeSyncItemsList;
            if (IntimeSyncHelper.IsInTimeBatchRunning() && !Test.isRunningTest()) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Selected Intime Sync Items has been queued successfully.'));
            this.triggeredSyncActionSuccessfully = true;
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
        return null;
    }  

    /** 
    *  @description : Redirect to list view page
    **/ 
    public PageReference returnToListViewPage() {
        this.standardSetController.setSelected(new List<InTimeSyncItem__c>());
        return this.standardSetController.cancel();
    }  
}