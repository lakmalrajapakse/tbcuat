trigger SMSMessageQueueTrigger on SMS_Message_Queue__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new SMSMessageQueueTriggerHandler().run();
}