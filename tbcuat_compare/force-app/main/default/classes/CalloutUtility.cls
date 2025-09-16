public class CalloutUtility {
    public static HttpResponse doCallout(String strEndpoint, String strMethod, String strBody, Map<String, String> requestHeaders){
        Http http = new Http();
        HttpResponse response = null;
        try{
            HttpRequest req = buildHttpRequest(strEndpoint, strMethod, strBody, requestHeaders);
            response = http.send(req);  
        }Catch(Exception ex){
            response = new HttpResponse();
            response.setBody('Exception : '+ex);
            response.setStatus('Error');
            response.setStatusCode(500);
            system.debug('Exception : '+ex);
        }
        return response;
    }
    
    public static HttpRequest buildHttpRequest(String strEndpoint, String strMethod, String strBody, Map<String, String> requestHeaders) {
        HttpRequest request = new HttpRequest();
        if(String.isNotEmpty(strEndpoint)){
            request.setEndpoint(strEndpoint.trim());
        }
        request.setMethod(strMethod);
        if(!String.isBlank(strBody)) {
            request.setBody(strBody);
        }
        if(requestHeaders != null) {
            for(String strKey : requestHeaders.keySet()) {
                request.setHeader(strKey, requestHeaders.get(strKey));
            }
        }
        request.setTimeout(120000);
        return request;
    }
    
    public static Map<String, String> buildRequestHeader(){
        Map<String, String> requestHeaders = new Map<String, String>();
        requestHeaders.put('Content-Type', 'application/json');
        return requestHeaders;
    }
}