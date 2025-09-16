/**
*   @description Batch used to send financial tags from salesforce to intime
**/
public with sharing class IntimeFinancialTagSendBatch implements Database.Batchable<IntimeObjectPayload__mdt>, Database.AllowsCallouts{
    
    private Set<String> payloadTypes;

    /**
    *  @description : Constructor
    **/ 
    public IntimeFinancialTagSendBatch(Set<String> payloadTypes) {
        this.payloadTypes = payloadTypes;
    }

    /**
    *  @description : Batch start method 
    **/ 
    public List<IntimeObjectPayload__mdt> start(Database.BatchableContext BC) { 
        return [SELECT Id, IntimeFieldReference__c, MethodName__c, Payload__c, ResponseElementName__c, Type__c FROM IntimeObjectPayload__mdt WHERE Type__c IN: this.payloadTypes];
    }

    /**
    *  @description : Batch Execute method
    **/ 
    public void execute(Database.BatchableContext BC, List<IntimeObjectPayload__mdt> scope) {
        try {
            IntimeFinancialTagHandler intimeFinancialTagSyncHandler = new IntimeFinancialTagHandler();
            intimeFinancialTagSyncHandler.syncToInTime(scope[0]);
        } catch(Exception ex) {
        }
    }
    
    /**
    *  @description : Batch Finish Method
    **/ 
    public void finish(Database.BatchableContext BC) {
    }
}