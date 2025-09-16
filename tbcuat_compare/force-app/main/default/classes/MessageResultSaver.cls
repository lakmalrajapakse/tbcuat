/**
 * MessageResultSaver is a singleton class responsible for managing the queue of messages
 * to be saved and handling the insertion of those messages into the Salesforce database.
 * It also manages error logging with a configurable cap on the number of error logs.
 */
public class MessageResultSaver {
    // Queue to hold messages pending insertion into the database.
    private List<Mass_Message__c> messageQueue;
  // Error count and logs
  private List<String> errorLogs;
    // Logger for recording errors encountered during message processing.
    private CommunicationManagerErrorLogger errorLogger;

    // Maximum number of error logs to keep to prevent excessive logging (configurable).
    private Integer maxErrorLogs;

    // Counter for the number of errors logged.
    private Integer errorCount;

    // Single instance of MessageResultSaver for the Singleton pattern.
    private static final MessageResultSaver instance = new MessageResultSaver();
   /**
     * Provides access to the singleton instance of the MessageResultSaver class.
     *
     * @return The single instance of MessageResultSaver.
     */


     public static MessageResultSaver getInstance() {
        return instance;
    }

    // ... other class methods ...

    // Method to get the error count
    public Integer getErrorCount() {
        return errorCount;
    }

    // Method to get the error logs
    public List<String> getErrorLogs() {
        return errorLogs;
    }
    //additional methods for testing purposes
    public Integer getMessageQueueSize() {
        return messageQueue.size();
    }

    public void clearMessageQueue() {
        messageQueue.clear();
    }

    public List<Mass_Message__c> getMessageQueue() {
        return messageQueue;
    }

    // Private constructor to prevent instantiation from outside the class.
    private MessageResultSaver() {
        messageQueue = new List<Mass_Message__c>();
        errorLogger = CommunicationManagerErrorLogger.getInstance();
        maxErrorLogs = 10; // Default maximum error logs (can be configured).
        errorCount = 0;
        errorLogs = new List<String>();

    }

 
    /**
     * Configures the maximum number of error logs to keep.
     *
     * @param maxLogs The maximum number of error logs to keep.
     */
    public void setMaxErrorLogs(Integer maxLogs) {
        maxErrorLogs = Math.max(maxLogs, 0); // Ensure it's non-negative.
    }

    /**
     * Accepts a list of message types and a ContactWrapper object, creating a new Mass_Message__c
     * record for each message type and adding it to the message queue. If an exception occurs,
     * logs the error using CommunicationManagerErrorLogger.
     *
     * @param types A list of message types (e.g., SMS, Email).
     * @param contactWrapper The contact wrapper containing message details.
     */
    public void saveResult(List<String> types, ContactWrapper contactWrapper) {
            try {
                if (contactWrapper != null) {
                    for (String type : types) {
                        Mass_Message__c message = new Mass_Message__c(
                            Type__c = type,
                            Contact__c = contactWrapper.conId,
                            Message__c = contactWrapper.message,
                            Status__c = contactWrapper.status
                        );
                        try {
                            messageQueue.add(message);
    
                        } catch (Exception e) {
                            errorLogger.logError('Error in saveResult: ' + e.getMessage());
                            errorCount++;                      
                        }
                    }
                } else {
                if (errorCount < maxErrorLogs) {
                    errorLogger.logError('Error in saveResult - contactWrapper is null');
                    errorCount++;               
    
                }}
            } catch (Exception e) {
                if (errorCount < maxErrorLogs) {
                    errorLogger.logError('Error in saveResult: ' + e.getMessage());
                    errorCount++;               
    
                }}
            }

    

    /**
     * Inserts the queued messages into the Salesforce database. If a message is of type 'SMS',
     * it is converted to a MobileMessaging_SMS_Message__c record before insertion. Handles
     * exceptions by logging errors up to a maximum number defined by maxErrorLogs.
     */
    public void insertQueue() {
        // Temporary list to hold messages for insertion.
        List<Mass_Message__c> messagesToInsert;

        // List to hold SMS messages specifically.
        List<MobileMessaging_SMS_Message__c> smsMessagesToInsert = new List<MobileMessaging_SMS_Message__c>();

        // Transfer messages from the queue to the temporary list and clear the queue.
        messagesToInsert = new List<Mass_Message__c>(messageQueue);
        messageQueue.clear();

        // Process each record and prepare SMS messages for insertion.
        for (Mass_Message__c record : messagesToInsert) {
            if (record.Type__c == 'SMS') {
                MobileMessaging_SMS_Message__c smsMessage = new MobileMessaging_SMS_Message__c(
                    Contact__c = record.Contact__c,
                    Message_Content__c = record.Message__c,
                    Status__c = record.Status__c,
                    Source__c = 'Bulk SMS',
                    Direction__c = 'outbound'
                );
                smsMessagesToInsert.add(smsMessage);
            }
            // Additional processing for other message types could be added here.
        }

        try {
            // Insert SMS messages into the database.
            if (!smsMessagesToInsert.isEmpty()) {
                Database.insert(smsMessagesToInsert);
            }
            // Insertion logic for other message types would go here.
        } catch (Exception e) {
            if (errorCount < maxErrorLogs) {
                errorLogger.logError('Error during insertQueue: ' + e.getMessage());
                errorCount++;
            }
        }

        // Insert any error logs if necessary.
        try {
            errorLogger.saveErrors();
        } catch (Exception e) {
            System.debug('Error inserting error logs: ' + e.getMessage());
        }
    }
}