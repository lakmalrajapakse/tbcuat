trigger SMSMessageTrigger on MobileMessaging_SMS_Message__c (before insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        SMSMessageTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        SMSMessageTriggerHandler.afterInsert(Trigger.new);
    }
}