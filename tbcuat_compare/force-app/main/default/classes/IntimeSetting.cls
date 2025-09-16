/**
* @description : Apex class to manage intime settting
**/
public with sharing class IntimeSetting {
    
    private static InTimeSetting__mdt inTimeSetting;

    static {
        if (inTimeSetting == null) {
            List<InTimeSetting__mdt> inTimeSettingsList = [SELECT Id, Endpoint__c, AgencyReferenceCode__c, Username__c, Password__c, AuthenticatePayload__c, 
                ModifiedItemsType__c, LeaverHoldingPeriod__c, LeaverPayload__c, SearchHolidayClaimPayload__c, HolidayClaimByRefPayload__c, WorkerWithNoTimesheet__c, HolidayHoursInADay__c, MaximumRetryLimit__c FROM InTimeSetting__mdt LIMIT 1];
            if (!inTimeSettingsList.isEmpty()) {
                inTimeSetting = inTimeSettingsList[0];
            }
        }
    }

    /**
    * @description Method to get Endpoint
    **/
    public static String getEndpoint(){
        return !String.isBlank(inTimeSetting?.Endpoint__c) ? inTimeSetting.Endpoint__c : '';
    }

    /**
    * @description Method to get Agency reference code
    **/
    public static String getAgencyReferenceCode(){
        return !String.isBlank(inTimeSetting?.AgencyReferenceCode__c) ? inTimeSetting.AgencyReferenceCode__c : '';
    }

    /**
    * @description Method to get user name 
    **/
    public static String getUsername(){
        return !String.isBlank(inTimeSetting?.Username__c) ? inTimeSetting.Username__c : '';
    }

    /**
    * @description Method to get password
    **/
    public static String getPassword(){
        return !String.isBlank(inTimeSetting?.Password__c) ? inTimeSetting.Password__c : '';
    }

    /**
    * @description Method to get authenticate payload
    **/
    public static String getAuthenticatePayload(){
        return !String.isBlank(inTimeSetting?.AuthenticatePayload__c) ? inTimeSetting.AuthenticatePayload__c : '';
    }

    /**
    * @description Method to get modified items type
    **/
    public static String getModifiedItemsType(){
        return !String.isBlank(inTimeSetting?.ModifiedItemsType__c) ? inTimeSetting.ModifiedItemsType__c : '';
    }

    /**
    * @description Method to get the leaver holding period
    **/
    public static Integer getLeaverHoldingPeriod(){
        return inTimeSetting?.LeaverHoldingPeriod__c != null ? Integer.valueOf(inTimeSetting.LeaverHoldingPeriod__c) : 0;
    }

    /**
    * @description Method to get the leaver payload
    **/
    public static String getLeaverPayload(){
        return !String.isBlank(inTimeSetting?.LeaverPayload__c) ? inTimeSetting.LeaverPayload__c : '';
    }

    /**
    * @description Method to get the leaver payload
    **/
    public static String getSearchHolidayClaimPayload(){
        return !String.isBlank(inTimeSetting?.SearchHolidayClaimPayload__c) ? inTimeSetting.SearchHolidayClaimPayload__c : '';
    }

    /**
    * @description Method to get the leaver payload
    **/
    public static String getHolidayClaimByRefPayload(){
        return !String.isBlank(inTimeSetting?.HolidayClaimByRefPayload__c) ? inTimeSetting.HolidayClaimByRefPayload__c : '';
    }

    /**
    * @description Method to get worker with no timesheet period
    **/
    public static Integer getWorkerWithNoTimesheetPeriod(){
        return inTimeSetting?.WorkerWithNoTimesheet__c != null ? Integer.valueOf(inTimeSetting.WorkerWithNoTimesheet__c) : 0;
    }

    /**
    * @description Method to get holiday hours in a day
    **/
    public static Decimal getHolidayHoursInADay(){
        return inTimeSetting?.HolidayHoursInADay__c != null ?inTimeSetting.HolidayHoursInADay__c : 0;
    }

    /**
    * @description Method to get maximum retry limit
    **/
    public static Decimal getMaximumRetryLimit(){
        return inTimeSetting?.MaximumRetryLimit__c != null ? Integer.valueOf(inTimeSetting.MaximumRetryLimit__c) : 5;
    }
}