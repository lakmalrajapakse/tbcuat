public class SMSRequestBuilder {
    public SMSRequest buildRequest(String apiToken, String phoneNumber, String apiUrl, String to, String body) {
        Map<String, String> headers = createHeaders(apiToken);
        Map<String, Object> payload = createPayload(phoneNumber, to, body);
        String payloadJSON = serializePayload(payload);

        return new SMSRequest(apiUrl, headers, payloadJSON);
    }

    private Map<String, String> createHeaders(String apiToken) {
        Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiToken,
            'Content-Type' => 'application/vnd.textus+jsonld',
            'Accept' => 'application/vnd.textus+jsonld'
        };
        return headers;
    }

    private Map<String, Object> createPayload(String phoneNumber, String to, String body) {
        Map<String, Object> payload = new Map<String, Object>{
            'from' => phoneNumber,
            'to' => to,
            'body' => body
        };
        return payload;
    }

    private String serializePayload(Map<String, Object> payload) {
        return JSON.serialize(payload);
    }
}