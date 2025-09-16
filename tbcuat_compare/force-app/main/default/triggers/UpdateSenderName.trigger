trigger UpdateSenderName on MobileMessaging_SMS_Message__c (before insert, before update) {
    // Prepare sets to hold Contact and User IDs
    Set<Id> contactIds = new Set<Id>();
    Set<Id> userIds = new Set<Id>();

    // Determine which IDs we need to query
    for (MobileMessaging_SMS_Message__c message : Trigger.new) {
        if (message.Direction__c == 'inbound' && message.Contact__c != null) {
            contactIds.add(message.Contact__c);
        } else {
            userIds.add(message.OwnerId);
        }
    }

    // Query for Contact names
    Map<Id, Contact> contactsMap = new Map<Id, Contact>([
        SELECT Id, Name FROM Contact WHERE Id IN :contactIds
    ]);

    // Query for User names
    Map<Id, User> usersMap = new Map<Id, User>([
        SELECT Id, Name FROM User WHERE Id IN :userIds
    ]);

    // Set the Sender_Name__c field on records before they are inserted or updated
    for (MobileMessaging_SMS_Message__c message : Trigger.new) {
        if (message.Direction__c == 'inbound') {
            Contact contact = contactsMap.get(message.Contact__c);
            if (contact != null) {
                message.Sender_Name__c = contact.Name;
            }
        } else {
            User owner = usersMap.get(message.OwnerId);
            if (owner != null) {
                message.Sender_Name__c = owner.Name;
            }
        }
    }
}