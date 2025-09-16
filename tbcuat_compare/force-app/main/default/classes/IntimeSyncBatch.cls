/**
*   @description Implements the Intime sync process
**/
public with sharing class IntimeSyncBatch implements Database.Batchable<InTimeSyncItem__c>, Database.AllowsCallouts, Database.Stateful, Database.RaisesPlatformEvents{
    
    private InTimeObject__mdt intimeObject;

    /**
    *  @description Batch constructor
    **/ 
    public IntimeSyncBatch(InTimeObject__mdt intimeObject) {
        this.intimeObject = intimeObject;
        IntimeSyncHelper.updateRetryCount(this.intimeObject.Object__c);     
    }
    
    /**
    *  @description : Batch start method 
    **/ 
    public List<InTimeSyncItem__c> start(Database.BatchableContext BC) { 
        return [SELECT Id, Name, SourceRecordId__c, InTimeSyncLog__c, ObjectType__c, RetryCount__c FROM InTimeSyncItem__c 
            WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND ObjectType__c =: this.intimeObject.Object__c];
    }

    /**
    *  @description : Batch Execute method
    **/
    public void execute(Database.BatchableContext BC, List<InTimeSyncItem__c> scope) {
        try {
            IIntimeSyncHandler syncHandler = (IIntimeSyncHandler)Type.forName(this.intimeObject.HandlerName__c).newInstance();
            if (syncHandler != null)  syncHandler.syncToIntime(scope,this.intimeObject);
        } catch(Exception ex) {
           
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
        // Trigger the next intime sync object
        if (!Test.isRunningTest()) {
            IntimeSyncProcessor.triggerNextIntimeSyncBatch(IntimeConstants.INTIME_OBJECT_SOURCE_SALESFORCE);
        }
    }
}