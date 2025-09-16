public class SMSSenderService {
    public void sendSMS(String to, String body) {
        SMSSettings settings = SMSSettings.getInstance();
        String apiToken = settings.apiToken;
        String phoneNumber = settings.senderPhoneNumber;
        String apiUrl = settings.apiUrl;

        SMSRequestBuilder requestBuilder = new SMSRequestBuilder();
        SMSRequest request = requestBuilder.buildRequest(apiToken, phoneNumber, apiUrl, to, body);

        SMSRequestSender sender = new SMSRequestSender();
        HttpResponse httpResponse = sender.sendRequest(request);

        // Convert HttpResponse to SMSResponse
        SMSResponse smsResponse = new SMSResponse(httpResponse);

        if (smsResponse.isSuccess()) {
            System.debug('SMS sent successfully!');
        } else {
            String errorTitle = smsResponse.getErrorTitle();
            String errorDetail = smsResponse.getErrorDetail();
            throw new SMSSendException('Failed to send SMS. Error Title: ' + errorTitle + ', Error Detail: ' + errorDetail);
        }
    }
}