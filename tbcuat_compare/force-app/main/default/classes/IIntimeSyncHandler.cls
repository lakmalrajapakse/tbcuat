/**
*  @description Interface for sync handler
**/
public interface IIntimeSyncHandler {

    // triggers the sync to intime 
    void syncToIntime(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject);
}