public class SMSRequestSender {
    public HttpResponse sendRequest(SMSRequest request) {
        Http http = new Http();
        HttpRequest httpRequest = createHttpRequest(request);

        return http.send(httpRequest);
    }

    private HttpRequest createHttpRequest(SMSRequest request) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(request.apiUrl);
        httpRequest.setMethod('POST');

        // Set individual headers
        for (String headerName : request.headers.keySet()) {
            httpRequest.setHeader(headerName, request.headers.get(headerName));
        }

        httpRequest.setBody(request.payloadJSON);
        return httpRequest;
    }
}