/**
 * CommunicationManagerErrorLogger is a singleton class that manages the collection
 * and insertion of error log records into a custom Salesforce object.
 * The class ensures that only one instance of itself is created within the Salesforce
 * org to manage error logs efficiently.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 */
public class CommunicationManagerErrorLogger {
    // Static instance variable for the singleton pattern
    private static CommunicationManagerErrorLogger instance;
    
    // Instance variable to hold the error log records before they are inserted into Salesforce
    private List<Communication_Manager_Error_Log__c> errorLogs;

    /**
     * Private constructor for the singleton class.
     * It initializes the list to store error log records.
     */
    private CommunicationManagerErrorLogger() {
        errorLogs = new List<Communication_Manager_Error_Log__c>();
    }

    /**
     * Public method to get the instance of the CommunicationManagerErrorLogger.
     * If the instance is null, a new one is created.
     *
     * @return The singleton instance of CommunicationManagerErrorLogger.
     */
    public static CommunicationManagerErrorLogger getInstance() {
        if (instance == null) {
            instance = new CommunicationManagerErrorLogger();
        }
        return instance;
    }

    /**
     * Method to log an error message by creating a new error log record
     * and adding it to the list of error logs. This is an instance method now,
     * ensuring that we are adding to the instance's errorLogs list.
     *
     * @param errorMessage The error message to be logged. Should not be null.
     */
    public void logError(String errorMessage) {
        if (errorMessage != null) {
            // Create a new custom error log record with the provided error message
            Communication_Manager_Error_Log__c errorLog = new Communication_Manager_Error_Log__c(
                Error_Message__c = errorMessage
            );
            
            // Log the error message to the Salesforce debug logs
            System.debug('Error: ' + errorMessage);
            
            // Add the newly created error log record to this instance's list of error logs
            this.errorLogs.add(errorLog);
        } else {
            // Log an attempt to add a null error message for debugging purposes
            System.debug('Attempted to log a null error message.');
        }
    }

    /**
     * Method to insert the collected error log records into Salesforce.
     * It checks if there are any logs in the list before attempting to insert them.
     * After insertion, it clears the list to avoid duplicate logging.
     */
    public void saveErrors() {
        if (!this.errorLogs.isEmpty()) {
            insert this.errorLogs; // Perform DML operation
            this.errorLogs.clear(); // Clear the list after insertion to avoid re-inserting the same logs
        }
    }

    /**
     * Getter method to access the errorLogs list for testing purposes.
     *
     * @return The errorLogs list.
     */
    public List<Communication_Manager_Error_Log__c> getErrorLogs() {
        return errorLogs;
    }
}