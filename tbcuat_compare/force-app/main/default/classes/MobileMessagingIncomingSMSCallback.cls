@RestResource(urlMapping='/MobileMessagingIncomingSMS/*')
global class MobileMessagingIncomingSMSCallback {

    @HttpPost
    global static String handleMessage() {
        
        try {
            RestRequest req = RestContext.request;
            SMSSettings settings = SMSSettings.getInstance();   
            Map<String, Object> jsonPayload = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            String converFromHex;
            boolean verified = false;
            for (String headerName : req.headers.keySet()) {
                if(headerName=='X-TextUs-Signature')
                {
                    converFromHex = req.headers.get(headerName);
                }
            }

            if(!Test.isRunningTest()){
                    verified = Crypto.verifyHmac(
                    'hmacSHA256',
                    blob.valueOf(req.requestBody.toString()),
                    blob.valueOf(settings.textUsPrivateKey),
                    encodingutil.convertFromHex(converFromHex)
                );
            }
            else
            {
                verified = true;
            }

          
            if(verified && !String.isBlank(settings.textUsPrivateKey)){
                Map<String, Object> messageObject = (Map<String, Object>) jsonPayload.get('message');
                Map<String, Object> conversationObject = (Map<String, Object>) jsonPayload.get('conversation');
                if (jsonPayload.get('action') != 'message.received') {
                    return 'Action is not incoming';
                }
                
                
                String body = (String) messageObject.get('body');
                System.debug(body);
                String formattedNumber = (String) conversationObject.get('formattedPhoneNumber');
                String fromNumber = (String) conversationObject.get('phoneNumber');
                
                        // Standardize the phone number format to +XXXXXXXXXX
                        List<Contact> relatedContacts = new List<Contact>();
                
                        Integer countryCodeLength = formattedNumber.indexOf(' ');

                        // Extract the country code and the remaining digits
                        String countryCode = fromNumber.substring(0, countryCodeLength);
                        String remainingDigits = fromNumber.substring(countryCodeLength);
                        
                        // Construct the list of values
                        List<String> phoneNumberValues = new List<String>{
                            fromNumber,                              // Original international format
                            '0' + remainingDigits,                  // With leading zero
                            remainingDigits                          // Without country code and leading zero
                        };
                            // Query 'Contact' using potentially matching 'MobilePhone' values
                            relatedContacts = [
                                SELECT Id
                                FROM Contact
                                WHERE MobilePhone IN :phoneNumberValues
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            ];
            
                if (!relatedContacts.isEmpty()) {
                   
                    // Attempt to find the last SMS message for default sender info
                    List<MobileMessaging_SMS_Message__c> lastSMS = [SELECT Sender__c, Sender_Name__c FROM MobileMessaging_SMS_Message__c WHERE Contact__c = :relatedContacts[0].Id ORDER BY CreatedDate DESC LIMIT 1];

                    // Default sender details (could be replaced with actual admin details)
                    String defaultSenderId;
                    String defaultSenderName;
                    if(Test.isRunningTest()){
                        defaultSenderId = UserInfo.getUserId();
                        defaultSenderName = 'SMS Admin';
                    } else {
                        defaultSenderId = settings.adminId; // Replace with actual Admin Id
                        defaultSenderName = settings.adminName; // Replace with actual Admin Name        
                    }                

                    MobileMessaging_SMS_Message__c newSMS = new MobileMessaging_SMS_Message__c(
                    
                        Contact__c = relatedContacts[0].Id,
                        Message_Content__c = body,
                        Short_Message__c = body.left(255).trim(),
                        Status__c = 'Received',
                        Direction__c = 'inbound',
                        Source__c = 'incoming',
                        // Set Sender__c and Sender__Name__c based on last message or default admin details
                        Sender__c = lastSMS.isEmpty() ? defaultSenderId : lastSMS[0].Sender__c,
                        Sender_Name__c = lastSMS.isEmpty() ? defaultSenderName : lastSMS[0].Sender_Name__c
                    );

                    insert newSMS;
                    system.debug('SPC FromNumber ' + fromNumber);
                    system.debug('SPC body ' + body);
                    system.debug('SPC newSMS.Contact__c ' + newSMS.Contact__c);
                    system.debug('SPC newSMS.Sender__c ' + newSMS.Sender__c);
                    SMSEventLogger.logSMSEvent('inbound', fromNumber, body, newSMS.Contact__c, newSMS.Sender__c);
                    return 'Message Recevied';
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return(e.getMessage());
        }
        return('It seems nothing has ignited the process');
    }
    // Method to standardize phone number format to +XXXXXXXXXX
    @testvisible
    private static String standardizePhoneNumber(String phoneNumber) {
        // Add leading '+' if not present
        if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+' + phoneNumber;
        }
        return phoneNumber;
    } 
    
}