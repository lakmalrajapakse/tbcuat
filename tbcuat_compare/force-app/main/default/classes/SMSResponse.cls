public class SMSResponse {
    private Map<String, Object> responseMap;

    public SMSResponse(System.HttpResponse httpResponse) {
        responseMap = parseResponse(httpResponse.getBody());
    }
    

    public Boolean isSuccess() {
        // Check for success response structure
        return responseMap.containsKey('@type') && responseMap.get('@type').equals('Message');
    }

    public String getErrorTitle() {
        return (String) responseMap.get('title');
    }

    public String getErrorDetail() {
        return (String) responseMap.get('detail');
    }

    private Map<String, Object> parseResponse(String responseBody) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        } catch (Exception e) {
            throw new SMSSendException('Failed to parse JSON response: ' + e.getMessage());
        }
    }
}