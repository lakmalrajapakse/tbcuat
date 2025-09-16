/**
* @description : Apex class to manage inpay settting
**/
public with sharing class InpaySetting {
    
    private static InPaySetting__mdt inPaySetting;

    static {
        if (inPaySetting == null) {
            List<InPaySetting__mdt> inPaySettingsList = [SELECT Id, Endpoint__c, CompanyId__c, Username__c, Password__c, AuthenticatePayload__c FROM InPaySetting__mdt LIMIT 1];
            if (!inPaySettingsList.isEmpty()) {
                inPaySetting = inPaySettingsList[0];
            }
        }
    }

    /**
    * @description Method to get Endpoint
    **/
    public static String getEndpoint(){
        return !String.isBlank(inPaySetting?.Endpoint__c) ? inPaySetting.Endpoint__c : '';
    }

    /**
    * @description Method to get CompanyId
    **/
    public static String getCompanyId(){
        return !String.isBlank(inPaySetting?.CompanyId__c) ? inPaySetting.CompanyId__c : '';
    }

    /**
    * @description Method to get user name 
    **/
    public static String getUsername(){
        return !String.isBlank(inPaySetting?.Username__c) ? EncodingUtil.urlEncode(inPaySetting.Username__c,'UTF-8') : '';
    }

    /**
    * @description Method to get password
    **/
    public static String getPassword(){
        return !String.isBlank(inPaySetting?.Password__c) ? EncodingUtil.urlEncode(inPaySetting.Password__c,'UTF-8'): '';
    }

    /**
    * @description Method to get authenticate payload
    **/
    public static String getAuthenticatePayload(){
        return !String.isBlank(inPaySetting?.AuthenticatePayload__c) ? inPaySetting.AuthenticatePayload__c : '';
    }
}