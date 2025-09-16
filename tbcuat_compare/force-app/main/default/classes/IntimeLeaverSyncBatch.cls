/**
*   @description Implements the Intime leaver sync process
**/
public with sharing class IntimeLeaverSyncBatch implements Database.Batchable<Contact>, Database.AllowsCallouts{

    private Date dateToSync;

    /**
    *  @description Batch constructor
    **/ 
    public IntimeLeaverSyncBatch() {
        this.dateToSync = System.today().addDays(-1 * IntimeSetting.getWorkerWithNoTimesheetPeriod());
    }
    
    /**
    *  @description : Batch start method 
    **/ 
    public List<Contact> start(Database.BatchableContext BC) { 
        return [SELECT Id FROM Contact WHERE LeavingDate__c =: this.dateToSync OR DateWorkerSendToIntimeAsLeaver__c =: System.today()];
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        try {
            IntimeLeaverSyncHandler syncHandler = new IntimeLeaverSyncHandler();
            if (syncHandler != null)  syncHandler.syncToIntime(scope[0].Id);
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
    }
}