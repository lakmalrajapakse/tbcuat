public class SMSRequest {
    public String apiUrl { get; private set; }
    public Map<String, String> headers { get; private set; }
    public String payloadJSON { get; private set; }

    public SMSRequest(String apiUrl, Map<String, String> headers, String payloadJSON) {
        this.apiUrl = apiUrl;
        this.headers = headers;
        this.payloadJSON = payloadJSON;
    }
}