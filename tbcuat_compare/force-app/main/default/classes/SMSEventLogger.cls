public class SMSEventLogger {

    public static void logSMSEvent(String direction, String phoneNumber, String messageBody, Id contactId, Id notifiedUser) {
        
        TextIUS_Settings__c settings = SettingsProvider.getSettings();
        if (settings == null) {  
            System.debug('Settings not found');
            return;
        }
        
        Integer messageEventLengthToUse = Integer.valueOf(settings.get('SMS_Event_Description_Length__c'));
        
        Event smsEvent = new Event(
            Subject = 'SMS ' + direction + ' ' + (direction == 'outbound' ? 'to' : 'from') + ' ' + phoneNumber,
            WhoId = contactId,
            StartDateTime = System.now(),
            EndDateTime = System.now().addMinutes(1),  
            Type = 'SMS',
            Description = messageBody.left(messageEventLengthToUse)
        );
        
        try {
            insert smsEvent;
            
            if(direction == 'inbound') {
                String fullName;
                Contact con = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
                
                if (String.isNotBlank(con.FirstName)) {
                    fullName = con.FirstName + ' ' + con.LastName;
                } else {
                    fullName = con.LastName;
                }
                
                // Get the custom Notification type
                List<CustomNotificationType> templateInfoDetail = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'New_SMS_Received'];

                // Create a new custom notification
                Messaging.CustomNotification currNotification = new Messaging.CustomNotification();

// Set the contents for the notification
currNotification.setTitle('New SMS Received');
currNotification.setBody('You have received a new SMS from ' + fullName + '.');
currNotification.setNotificationTypeId(templateInfoDetail[0].Id);
currNotification.setTargetId(contactId);
Set<string> rIds= new Set<string>(); 
rIds.add(notifiedUser);
// Send the notification
try {
    currNotification.send(rIds);
    System.debug('Notification sent' + rIds);



} catch (Exception e) {
    System.debug('Problem sending notification: ' + e.getMessage());
}
                
            }

    } 
    catch (Exception e) {
        System.debug('Error creating SMS event: ' + e.getMessage());
    }
}
}