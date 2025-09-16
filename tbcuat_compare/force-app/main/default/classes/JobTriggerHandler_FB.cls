public class JobTriggerHandler_FB {
     public static void onBeforeUpdate(List<TR1__Job__c> newList, Map<Id, TR1__Job__c> oldMap){
        deleteJobFromBB(newList, oldMap);
    }
    
    public static void deleteJobFromBB(List<TR1__Job__c> newlist, Map<Id, TR1__Job__c> oldMap){
        List<TR1__Job__c> lstJob = new List<TR1__Job__c>();
        for(TR1__Job__c job : newlist){
            if(job.Job_Posted__c && String.isNotBlank(job.TR1__Status__c) && job.TR1__Status__c == 'Closed' && job.Advert_Deletion__c == 'DeleteWhenClosed'){
                lstJob.add(job);                
            }
        }
        if(lstJob.size() > 0){
            deleteFromBB(JSON.serialize(lstJob));
        }
    }
    
    @future(Callout = true)
    public static void deleteFromBB(String jobJSON){
        List<TR1__Job__c> newlist = (List<TR1__Job__c>)JSON.deserialize(jobJSON, List<TR1__Job__c>.class);
        User usr = [SELECT Id, VRT__Veritone_Username__c, VRT__Veritone_English_User__c, VRT__Veritone_French_User__c FROM User WHERE Id =: userinfo.getUserId() LIMIT 1];        
        VRT__Veritone_Credentials__c settings = VRT__Veritone_Credentials__c.getValues(UserInfo.getProfileId()) != null ? VRT__Veritone_Credentials__c.getValues(UserInfo.getProfileId()) : VRT__Veritone_Credentials__c.getOrgDefaults();
        if (settings != null && String.isNotBlank(settings.VRT__API_Key__c)) {
            long epochTime = System.currentTimeMillis();
            Blob secretBlob = Blob.valueOf(settings.VRT__Secret_Key__c);
            Blob messageBlob = Blob.valueOf(usr.VRT__Veritone_Username__c + '|' + epochTime + '|' + settings.VRT__API_Key__c);
            
            // Generate the HMAC-SHA256 hash
            Blob hmacSHA256 = Crypto.generateMac('HmacSHA256', messageBlob, secretBlob);
            // Convert the hash to a Base64-encoded string
            String encodedSignature = EncodingUtil.convertToHex(hmacSHA256);
            
            Map<String, Object> mapBody = new Map<String, Object>();
            
            Map<String, Object> mapAuthentication = new Map<String, Object>();
            mapAuthentication.put('api_key', settings.VRT__API_Key__c);
            mapAuthentication.put('time', epochTime);
            mapAuthentication.put('signature', encodedSignature);
            
            mapBody.put('authentication', mapAuthentication);
            
            Map<String, Object> mapIdentification = new Map<String, Object>();
            mapIdentification.put('client_id', settings.VRT__Client_Id__c);
            mapIdentification.put('adc_username', usr.VRT__Veritone_Username__c);
            
            mapBody.put('identification', mapIdentification);
            
            Map<String, Object> mapTransaction = new Map<String, Object>();
            for(TR1__Job__c job : newlist){
                try {
                    Map<String, Object> mapFilters = new Map<String, Object>();
                    mapFilters.put('job_reference', job.TR1__Job_Number__c);
                    mapTransaction.put('filters', mapFilters);
                    
                    mapBody.put('transaction', mapTransaction);
                    HttpResponse response = CalloutUtility.doCallout(settings.VRT__Advert_Deleting_Endpoint__c, 'POST', JSON.serializePretty(mapBody), CalloutUtility.buildRequestHeader());
                    if(response != null && String.isNotBlank(response.getBody())){
                        if(response.getStatusCode() == 200){
                            job.Veritone_Message__c = 'Job Deleted Successfully.';
                        }else{
                            job.Veritone_Message__c = response.getBody();
                        }
                    }else{
                        job.Veritone_Message__c = 'Integration has been failed, Please contact system admin.';    
                    }
                    job.Job_Posted__c = false;
                }Catch(Exception e){
                    job.Veritone_Message__c = e.getMessage()+'--'+e.getStackTraceString();  
                    job.Job_Posted__c = false;
                }
            }
            
            if(newlist.size() > 0){
                update newlist;
            }
        }
    }

}