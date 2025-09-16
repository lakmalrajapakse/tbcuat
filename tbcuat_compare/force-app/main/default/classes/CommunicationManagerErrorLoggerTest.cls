@IsTest
public class CommunicationManagerErrorLoggerTest {

    @IsTest
    static void testErrorLogging() {
        // Create an instance of CommunicationManagerErrorLogger
        CommunicationManagerErrorLogger errorLogger = CommunicationManagerErrorLogger.getInstance();

        // Log some error messages
        errorLogger.logError('Error 1');
        errorLogger.logError('Error 2');

        // Get the error logs (mock implementation)
        List<Communication_Manager_Error_Log__c> errorLogs = errorLogger.getErrorLogs();

        // Verify that error messages were added to the errorLogs list
        System.assertEquals(2, errorLogs.size(), 'Error logs should contain 2 entries.');

        // Log a null error message (should not be added)
        errorLogger.logError(null);

        // Verify that the null error message was not added to the errorLogs list
        System.assertEquals(2, errorLogs.size(), 'Error logs should still contain 2 entries.');

        // Save the error logs
        errorLogger.saveErrors();

        // Verify that the errorLogs list is cleared after saving
        System.assertEquals(0, errorLogs.size(), 'Error logs should be cleared after saving.');
    }

    @IsTest
    static void testSingletonPattern() {
        // Create multiple instances of CommunicationManagerErrorLogger
        CommunicationManagerErrorLogger logger1 = CommunicationManagerErrorLogger.getInstance();
        CommunicationManagerErrorLogger logger2 = CommunicationManagerErrorLogger.getInstance();

        // Verify that both instances are the same (Singleton pattern)
        System.assertEquals(logger1, logger2, 'Instances should be the same.');

        // Log an error in one instance
        logger1.logError('Test error');

        // Get the error logs from the other instance (mock implementation)
        List<Communication_Manager_Error_Log__c> errorLogs2 = logger2.getErrorLogs();

        // Verify that the error is present in the other instance
        System.assertEquals(1, errorLogs2.size(), 'Error should be present in the other instance.');

        // Save the error logs from one instance
        logger1.saveErrors();

        // Verify that the error logs are cleared in the other instance
        System.assertEquals(0, errorLogs2.size(), 'Error logs should be cleared in the other instance.');
    }
}