/**
* @description HTTP Client
**/
public class HttpClient {
    
    /**
    * @description Method to send the rest request to the server and returns the response back to the caller
    **/
    public static HttpResponse sendRequest(String body, Map<String, String> httpHeadersMap){
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(IntimeSetting.getEndpoint());
        httpRequest.setMethod(IntimeConstants.HTTP_METHOD_POST);
        setRequestHeaders(httpRequest,httpHeadersMap);
        if(!String.isBlank(body)) httpRequest.setBody(body);
        HTTPResponse response = new Http().send(httpRequest);
        return response;
    } 

    /**
    * @description Method to send the rest request to the server and returns the response back to the caller
    **/
    public static HttpResponse sendRequest(String endPoint, String httpMethod, String body, Map<String, String> httpHeadersMap){
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endPoint);
        httpRequest.setMethod(httpMethod);
        setRequestHeaders(httpRequest,httpHeadersMap);
        if(!String.isBlank(body)) httpRequest.setBody(body);
        HTTPResponse response = new Http().send(httpRequest);
        return response;
    } 
    
    /**
    * @description Method to set http request headers 
    * @param httpRequest Http request to set the headers for
    * @param httpHeaders Map of http headers
    **/
    private static void setRequestHeaders(HttpRequest httpRequest, Map<String, String> httpHeadersMap){
        for(String headerKey : httpHeadersMap.keySet()){
            httpRequest.setHeader(headerKey,httpHeadersMap.get(headerKey));
        }
    } 
}