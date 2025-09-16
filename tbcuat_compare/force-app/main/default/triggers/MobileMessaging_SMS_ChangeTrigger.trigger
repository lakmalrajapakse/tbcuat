trigger MobileMessaging_SMS_ChangeTrigger on MobileMessaging_SMS_Message__c (after insert, after update) {
    List<MessagingPlatformEvent__e> events = new List<MessagingPlatformEvent__e>();
    for (MobileMessaging_SMS_Message__c message : Trigger.New) {
        events.add(new MessagingPlatformEvent__e(Contact_Id__c = message.Contact__c));
    }
    EventBus.publish(events);
}