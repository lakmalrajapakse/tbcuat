/**
 * The MessageHandler class is responsible for handling the queuing of messages based on the
 * communication preferences indicated in ContactWrapper objects. It processes serialized
 * ContactWrapper JSON strings, determines the types of messages to be sent, and delegates
 * the saving of these results. It also captures and logs any errors that occur during the
 * processing of these messages.
 */
public class MessageHandler {
    /**
     * Processes a list of serialized ContactWrapper JSON strings to queue messages for
     * sending SMS, Email, or Push notifications as indicated by the preferences in each
     * ContactWrapper. Errors encountered during processing are logged.
     *
     * @param serializedContacts A List of serialized ContactWrapper JSON strings.
     */
    public static void queueMessages(List<String> serializedContacts) {
        // Initialize an empty list to collect error messages that may occur during processing.
        List<String> errorMessages = new List<String>();

        // Initialize a timestamp for monitoring processing time.
        Datetime startTime = Datetime.now();

        // Iterate over each serialized ContactWrapper JSON string.
        for (String serializedContact : serializedContacts) {
            try {
                // Initialize an empty list to collect the types of messages to send.
                List<String> types = new List<String>();

                // Deserialize the JSON string back into a ContactWrapper object.
                ContactWrapper contactWrapper = (ContactWrapper) JSON.deserialize(serializedContact, ContactWrapper.class);

                // Check if an SMS message should be sent and add 'SMS' to the types list if so.
                if (contactWrapper.sendSMS) {
                    types.add('SMS');
                }

                // Check if an Email message should be sent and add 'Email' to the types list if so.
                if (contactWrapper.sendEmail) {
                    types.add('Email');
                }

                // Check if a Push notification should be sent and add 'Push' to the types list if so.
                if (contactWrapper.sendPush) {
                    types.add('Push');
                }

                // If there are any types of messages to send, save the result using MessageResultSaver.
                if (!types.isEmpty()) {
                    MessageResultSaver.getInstance().saveResult(types, contactWrapper);
                }
            } catch (Exception e) {
                // If an exception occurs during processing, add its message to the errorMessages list.
                errorMessages.add('Error processing ContactWrapper: ' + e.getMessage());
            }
        }

        // Attempt to insert the queued messages into the database.
        try {
            System.debug(LoggingLevel.INFO, 'Inserting queue');
            MessageResultSaver.getInstance().insertQueue();
        } catch (Exception e) {
            // If an exception occurs during the insert operation, log the error message.
            errorMessages.add('Error inserting queue: ' + e.getMessage());
        }

        // Calculate processing time.
        Datetime endTime = Datetime.now();
        Long processingTimeMillis = endTime.getTime() - startTime.getTime();

        // If there are any error messages collected, log them or handle them as needed.
        if (!errorMessages.isEmpty()) {
            for (String errorMessage : errorMessages) {
                System.debug(LoggingLevel.ERROR, errorMessage);
            }
            // Additional error handling actions can be implemented here as required.

            // Notify administrators or developers about errors via email or other means.
            // Example: EmailService.notifyErrors(errorMessages, processingTimeMillis);
        }

        // Log the processing time.
        System.debug(LoggingLevel.INFO, 'MessageHandler processing time: ' + processingTimeMillis + ' ms');
    }
}