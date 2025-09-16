/**
*  @description Apex class to parse intime webservice response
**/
public with sharing class IntimeWebserviceParser {
    
    /**
    *  @description Method to parse authenticate response
    **/
    public static String getAuthenticateToken(String xmlBody) {
        return String.valueOf(IntimeSyncHelper.getResponse('authenticateResponse',xmlBody));
    }

    /**
    *  @description Method to get fetch response
    **/
    public static Object getFetchResponse(String xmlBody, String responseElement) {
        return IntimeSyncHelper.getResponse(responseElement,xmlBody);
    }

    /**
    *  @description Method to create or update response
    **/
    public static Object getCreateOrUpdateResponse(String xmlBody, String responseElement) {
        return IntimeSyncHelper.getResponse(responseElement,xmlBody);
    }
}