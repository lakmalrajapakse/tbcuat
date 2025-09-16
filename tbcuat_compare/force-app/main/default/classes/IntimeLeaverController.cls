/**
* @description Apex class to manage leaver in real time
**/
public with sharing class IntimeLeaverController {
    
    /** 
    *  @description : Method to create billing and billing lines
    **/ 
    @InvocableMethod(callout=true label='Mark Leavers In Intiome' description='Method to mark leavers in time' category='Other')
    public static List<InTimeSyncItem__c> markLeaverInTime(List<Id> contactIds) {
        List<InTimeSyncItem__c> intimeSyncItemsList = new List<InTimeSyncItem__c>();
        IntimeLeaverSyncHandler syncHandler = new IntimeLeaverSyncHandler();
        if (syncHandler != null) intimeSyncItemsList.add(syncHandler.syncToIntime(contactIds[0]));
        return intimeSyncItemsList;
    }
}