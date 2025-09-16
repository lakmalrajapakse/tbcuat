/**
* @description : Apex class to manage intime reverse sync settting
**/
public with sharing class IntimeReverseSyncSetting {
    
    private static IntimeReverseSyncSetting__c inTimeReverseSyncSetting;

    static {
        if (inTimeReverseSyncSetting == null) {
            inTimeReverseSyncSetting = IntimeReverseSyncSetting__c.getInstance();
        }
    }

    /**
    * @description Method to get Endpoint
    **/
    public static DateTime getDateTimeWhenSyncLastRanSuccessfully(){
        return inTimeReverseSyncSetting?.DateTimeWhenSyncLastRanSuccess__c != null ? inTimeReverseSyncSetting.DateTimeWhenSyncLastRanSuccess__c : null;
    }
}