/**
 * SMSMessageQueueable
 * This class implements the System.Queueable interface to process SMS messages from a custom queue asynchronously.
 * It queries SMS messages that are in 'Queue' status, sends them using the MobileMessagingServiceLayer, and updates their status to 'Processed'.
 *
 * Usage:
 * - Enqueue this class for execution to process queued SMS messages.
 * - Ensure that the MobileMessagingServiceLayer has a method sendSMSAsync to handle SMS sending.
 *
 * Created by: 1218 Global
 */
public class SMSMessageQueueable implements System.Queueable {

    /**
     * execute
     * The method Salesforce calls when executing the job. It processes messages in the 'Queue' status.
     *
     * @param context The QueueableContext object provided by the system containing the job's context.
     */
    public void execute(System.QueueableContext context) {
        // Query for queued SMS messages, limited to 200 to avoid governor limits
        List<SMS_Message_Queue__c> queueItems = [
            SELECT Id, Recipient_Phone_Number__c, Message_Content__c, Message_Record_Id__c, Source__c, Status__c,
            Sender_Name__c, Contact__c, Sender__c
            FROM SMS_Message_Queue__c 
            WHERE Status__c = 'Queue'
            LIMIT 50
        ];

        // Loop through each queued item and send SMS if the source is not 'incoming'
        List<SMS_Message_Queue__c> queueItemsToUpdate = new List<SMS_Message_Queue__c>();

        if(!queueItems.isEmpty()){
            for (SMS_Message_Queue__c queueItem : queueItems) {
                if (queueItem.Source__c != 'incoming') {    
                    // Call the SMS sending method from MobileMessagingServiceLayer
                    MobileMessagingServiceLayer.sendSMSAsync(
                        queueItem.Recipient_Phone_Number__c,
                        queueItem.Message_Content__c,
                        queueItem.Contact__c,
                        queueItem.Sender__c
                    );

                    // Update the queue item status to 'Processed'
                    queueItem.Status__c = 'Processed';
                } else {
                    queueItem.Status__c = 'Recieved';
                }
                queueItemsToUpdate.add(queueItem);
            }

            // Update all processed queue items in a single DML operation
            update queueItemsToUpdate;
            If(!Test.isRunningTest()){
                System.enqueueJob(new SMSMessageQueueable());
            }
    }

    }
}