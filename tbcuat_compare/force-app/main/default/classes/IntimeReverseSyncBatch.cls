/**
*   @description Implements the sync process from intime to salesforce
**/
public with sharing class IntimeReverseSyncBatch implements Database.Batchable<Object>, Database.AllowsCallouts{

    private Integer index;

    /**
    *  @description : Constructor
    **/ 
    public IntimeReverseSyncBatch(Integer index) {
        this.index = index;
    }

    /**
    *  @description : Batch start method 
    **/ 
    public List<Object> start(Database.BatchableContext BC) { 
        List<Object> objectsList = IntimeSyncHelper.getModifiedItemsFromIntime();
        return Test.isRunningTest() ? new List<Object>{objectsList[this.index]} : objectsList;
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<Object> scope) {
        try {
            IntimeReverseSyncHandler intimeReverseSyncHandler = new IntimeReverseSyncHandler();
            intimeReverseSyncHandler.syncToSalesforce(scope[0]);
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
        IntimeReverseSyncSetting__c inTimeReverseSyncSetting = IntimeReverseSyncSetting__c.getInstance();
        inTimeReverseSyncSetting.DateTimeWhenSyncLastRanSuccess__c = System.now();
        upsert inTimeReverseSyncSetting;
    }
}