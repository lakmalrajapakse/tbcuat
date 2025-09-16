/**
*  @description Helper class for Inpay sync
**/
public with sharing class InpaySyncHelper {
    
    /**
    * @description Method to get inpay token
    **/
    public static String getToken() {
        String token = '';
        HttpResponse httpResponse = HttpClient.sendRequest(
            InpaySetting.getEndpoint()+'/token',
            IntimeConstants.HTTP_METHOD_POST,
            String.format(InpaySetting.getAuthenticatePayload(),new List<String>{
                InpaySetting.getCompanyId(),
                InpaySetting.getUsername(),
                InpaySetting.getPassword()
            }),
            new Map<String,String>{
                'Content-Type' => 'application/x-www-form-urlencoded'
            }
        );
        if (httpResponse.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpResponse.getBody());
            if (responseMap.containsKey('access_token')) {
                token = String.valueOf(responseMap.get('access_token'));
            }
        }
        return token;
    }

    /**
    * @description Method to get intime token
    **/
    public static String getHolidayScheme(String employeeNumber) {
        String httpResponseBody = '';
        HttpResponse httpResponse = HttpClient.sendRequest(
            InpaySetting.getEndpoint()+'/api/HolidayScheme/'+employeeNumber,
            IntimeConstants.HTTP_METHOD_GET,
            '',
            new Map<String,String>{
                'Authorization' => 'Bearer '+getToken()
            }
        );
        if (httpResponse.getStatusCode() == 200) {
            httpResponseBody = httpResponse.getBody();
        }
        return httpResponseBody;
    }
}