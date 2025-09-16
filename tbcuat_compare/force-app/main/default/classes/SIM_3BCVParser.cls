public without sharing class SIM_3BCVParser {

	// Public static Map<Id,Id> formResponseConIdMap = new Map<Id,Id>();
    Public static Id contactId; 
    Public static Boolean forceErrorInTest = false;

    
    @invocableMethod	
    Public Static void sendCVToParser(List<List<b3f__FormResponse__c>> formResponseFromFlow) {

        System.debug('SPC Running sendCVToParser');
        List<b3f__FormResponse__c> formResponseList = formResponseFromFlow[0];
        b3f__FormResponse__c formResponse = formResponseList[0];

        // Get the Form
        List<b3f__Form__c> formList = new List<b3f__Form__c>([
            Select Id, CV_Upload_Field_Ref__c FROM b3f__Form__c WHERE Id =: formResponse.b3f__Form__c
            AND Parse_CV_on_this_form__c = true AND CV_Upload_Field_Ref__c != null
        ]);

        if(formList.size() > 0) {
            // Get FormResponse
            contactId = formResponse.b3f__New_Record_ID__c; 
        }
        
        if(formResponse != null && contactId != null) {
            // Get Content Document Link Id for Form Responses
            List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>([
                Select ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:formResponse.id
            ]);
            
            List<Id> contentDocLinkIds = new List<Id>();
            for(ContentDocumentLink cd : contentDocLinkList) {
                contentDocLinkIds.add(cd.ContentDocumentId);
            }
            
            // Get Content Document Id for Form Responses with a response
            List<ContentDocument> contentDocumentList = new List<ContentDocument>([
                Select Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN:contentDocLinkIds AND Title = 'Response.json'
            ]);
            
            List<Id> contentDocumentIds = new List<Id>();
            for(ContentDocument cd : contentDocumentList) {
                contentDocumentIds.add(cd.LatestPublishedVersionId);
            }        
    
            // Get Content Version
            List<ContentVersion> contentVersionList = new List<ContentVersion>([
                SELECT Id, VersionData FROM ContentVersion WHERE Id IN:contentDocumentIds
            ]);
                                 
            // Loop and Parse CV
            for(ContentVersion cv : contentVersionList) {
                Blob blobVersionData = cv.VersionData;
                String versionDataStr = blobVersionData.toString();
                Map<String, Object> versionDataMap = (Map<String, Object>) JSON.deserializeUntyped(versionDataStr);
                
                List<String> dataList = new List<String>();
                for (String key : versionDataMap.keySet()) {
                    // System.debug('SPC key: ' + key);
                    if(key == formList[0].CV_Upload_Field_Ref__c) {
                        // Adding some error handling because it can error here is the CV is too complicated.
                        try {
                            if (Test.isRunningTest() && forceErrorInTest) {
                                throw new StringException('Exception forced from Unit Test');
                            }               
                            dataList = versionDataMap.get(key).toString().split(',');
                        } catch(Exception e) {
                            System.debug('SPC data error: ' + e);
                            // Get the Form Response so we can update it
                            List<b3f__FormResponse__c> fm = new List<b3f__FormResponse__c>([
                                Select Id, Parse_this_Form_Response__c, b3f__ErrorMessage__c FROM b3f__FormResponse__c WHERE Id =: formResponse.Id 
                            ]);
                            b3f__FormResponse__c formRes = fm[0];
                            formRes.Parse_this_Form_Response__c = false;
                            formRes.b3f__ErrorMessage__c = 'Error CV could not be parsed - Too Complex';
                            update formRes;                            
                        }
                        
                    }
                }
                
                if(dataList.size() > 0) {
                    parseCVExternally(dataList, contactId, formResponse.Id);
                }            
            }            
        }
    } 
    
    Public Static void parseCVExternally(list<string> dataList, Id contactId, Id formResponseId) {
        // List Order, FileType, Body, Filename, ContentType
        Attachment resume = new Attachment();
        resume.Body = EncodingUtil.base64Decode(datalist[1]);
        // resume.Name = 'CVParser';
        resume.ContentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        resume.ParentId = contactId;
        // Set the ParentId if you already know what contact this resume should belong to, having this set means BH deduping code is skipped and automatically runs in context of that contact
        // You may also need to do checks on the size of the file as this can cause SF limits to be hit, recommended limit is 4 MB
        // system.debug('SPC Resume created > ' + resume);

        // Get the Form Response so we can update it
        List<b3f__FormResponse__c> fm = new List<b3f__FormResponse__c>([
            Select Id, Parse_this_Form_Response__c, b3f__ErrorMessage__c FROM b3f__FormResponse__c WHERE Id =: formResponseId 
        ]);
        b3f__FormResponse__c formRes = fm[0];

        // Check Contact Exists
        List<Contact> conList = new List<Contact>([
            Select Id from Contact WHERE Id =: contactId
        ]);
        // system.debug('SPC ConList ' + conList.size());
        
        if(conList.size() > 0) {
            TR1.Candidate cand = TR1.ResumeProcessorV2.createUpdateContact(resume, null);
            system.debug('Candidate Information extracted from Textkernel: ' + cand);
            //If you want to update what is committed, change contact information at top as well as in the contact variable
            IF(cand.IsParserError != true){
                //This is what commits the 'Candidate' to the database, upsert the contact, history records, skills, contact document
                cand = TR1.ResumeProcessorV2.performDML(cand);
                // system.debug('Response back from PerformDML: ' + cand);
                
                // Turn flag off
                formRes.Parse_this_Form_Response__c = false;
                formRes.b3f__ErrorMessage__c = 'CV Parsed sucessfully.';
                update formRes;
                
            }else{
                system.debug('Error whilst parsing: ' + cand.ParserErrorMsg);
                // Turn flag off
                formRes.Parse_this_Form_Response__c = false;
                formRes.b3f__ErrorMessage__c = 'Error CV could not be parsed.';
                update formRes;                
            }
        } else {
            // update form response here.
            // Turn flag off as its not associated to a known contact
            formRes.Parse_this_Form_Response__c = false;
            formRes.b3f__ErrorMessage__c = 'Error Contact could not be found.';
            update formRes;            
        }

   
    }           
}