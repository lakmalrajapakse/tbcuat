public class MobileMessagingServiceLayer {

    /**
     * Asynchronously sends an SMS message using the SMSSender class.
     * The method uses Salesforce's @future annotation to run in the background.
     *
     * @param toPhoneNumber The phone number to which the SMS should be sent.
     * @param message       The content of the SMS message.
     * @param recordId      The Salesforce record ID associated with the message for callback purposes.
     */
    @future(callout=true)
    public static void sendSMSAsync(String toPhoneNumber, String message, Id contactId, id senderId) {
        try {
            // Call the SMSSender method to send the SMS
            SMSSender.sendSMS(toPhoneNumber, message);
            System.debug('SMS sent successfully to ' + toPhoneNumber);
try {
    SMSEventLogger.logSMSEvent('outbound', toPhoneNumber, message, contactId, senderId);

} catch (Exception ex) {
    System.debug('An unexpected exception occurred while logging the SMS event.' + ex.getMessage());
}
            // Assuming SMSSender handles the callback logic, no need to construct callback URL or handle responses here.
        } catch (Exception ex) {
            // Log any unexpected exceptions during the process
            System.debug('An unexpected exception occurred: ' + ex.getMessage());
        }
    }
}