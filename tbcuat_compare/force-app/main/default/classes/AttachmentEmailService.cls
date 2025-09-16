global class AttachmentEmailService implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Extract and parse attachment IDs from the email body
        Set<String> setAttIds = new Set<String>();
        
        // Split the email body by commas, but handle single IDs gracefully
        List<String> lstAttIds = email.plainTextBody.contains(',') ? email.plainTextBody.split(',') : new List<String>{ email.plainTextBody };
            for (String idStr : lstAttIds) {
                idStr = idStr.trim();
                if (idStr.startsWith('00P')) { // Validate against ID format
                    setAttIds.add(idStr.substring(0, 18));
                }
            }
        system.debug('==================================== setAttIds : ' + setAttIds);
        List<Attachment> lstAtt = new List<Attachment>();
        
        // Query the attachments based on the provided IDs
        for (Attachment attch : [SELECT Id, ParentId, Name, ContentType, BodyLength, Body, Description FROM Attachment WHERE Id IN :setAttIds]) {
            attch.Name = truncateFileName(attch.Name);
            system.debug('==================================== attch : ' + attch);
            
            // Process the attachment as per your existing logic
            TR1.Candidate candidateResult = TR1.ResumeProcessor.createUpdateContact(attch, UserInfo.getSessionId());
            system.debug('==================================== candidateResult : ' + candidateResult);
            
            candidateResult.ContactId = attch.ParentId;
            system.debug('==================================== candidateResult.ContactId : ' + candidateResult.ContactId);
            
            // Perform DML as per your existing logic
            TR1.Candidate processedCandidate = TR1.ResumeProcessor.performDML(candidateResult);
            system.debug('==================================== processedCandidate : ' + processedCandidate);
            
            lstAtt.add(attch);
        }
        
        // Delete attachments if the custom label indicates
        if (Boolean.valueOf(Label.Delete_Attachment) && lstAtt.size() > 0) {
            delete lstAtt;
        }
        
        result.success = true;
        return result;
    }
    
    public static String truncateFileName(String fileName) {
        String prefix = 'VRT__Resume_';
        
        // Ensure the filename starts with the expected prefix
        if (!fileName.startsWith(prefix)) {
            return fileName; // Return original if it doesn't match the pattern
        }
        
        // Split the filename by underscores
        List<String> parts = fileName.split('_');
        
        // Ensure there are enough parts to get the required substring after the identifier
        if (parts.size() > 4) {
            // Create a new list starting from the fifth part onward
            List<String> remainingParts = new List<String>();
            for (Integer i = 4; i < parts.size(); i++) {
                remainingParts.add(parts[i]);
            }
            return String.join(remainingParts, '_');
        }
        
        return fileName; // Return original if the pattern doesn't match the expected structure
    }
}