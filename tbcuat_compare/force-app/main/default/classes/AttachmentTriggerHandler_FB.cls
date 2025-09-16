public without sharing class AttachmentTriggerHandler_FB {
    public static void onAfterInsert(List<Attachment> newList) {
        AttachmentUpdateOnContact(newList);
    }
    public static void AttachmentUpdateOnContact(List<Attachment> newList) {
        Set<String> setAttIds = new Set<String>();
        for (Attachment attch : newList) {  
            system.debug('=================================== String.valueOf(attch.ParentId) : '+String.valueOf(attch.ParentId));
            system.debug('=================================== String.valueOf(attch.ParentId).startsWithIgnoreCase : '+String.valueOf(attch.ParentId).startsWithIgnoreCase('003'));
            system.debug('=================================== attch.Name.contains : '+attch.Name.contains('VRT__Resume_'));
            if (String.isNotBlank(String.valueOf(attch.ParentId)) && String.valueOf(attch.ParentId).startsWithIgnoreCase('003') && attch.Name.contains('VRT__Resume_')) {
                setAttIds.add(attch.Id);
            }
        }
        system.debug('=================================== setAttIds.isEmpty() : '+setAttIds.isEmpty());
        if (!setAttIds.isEmpty()) {
            sendAttachmentIdsEmail(setAttIds);
        }
    }
    
    private static void sendAttachmentIdsEmail(Set<String> attachmentIds) {
        List<OrgWideEmailAddress> orgAddress = [SELECT Id, DisplayName FROM OrgWideEmailAddress LIMIT 1];       
        // Compose the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(orgAddress.size() > 0){
            email.setOrgWideEmailAddressId(orgAddress[0].Id);
        }
        email.setToAddresses(new String[] { Label.Veritone_Resume_Parsing_Service_URl });
        email.setSubject('Attachment IDs for Processing');
        email.setPlainTextBody(String.join(new List<String>(attachmentIds), ','));  // Include IDs as comma-separated string in the body
        
        List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email }, false);
        system.debug('=================================== emailResults : '+emailResults);
    }

}