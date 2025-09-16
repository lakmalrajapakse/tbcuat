/**
*  @description Apex class to manage the leaver data sync to intime
**/
public with sharing class IntimeLeaverSyncHandler {

    private String intimeSyncLog;
    
    /**
    *  @description Method to mark the contact as leaver in intime
    **/
    public InTimeSyncItem__c syncToIntime(Id contactId) {
        InTimeSyncItem__c intimeSyncItem = new InTimeSyncItem__c(
            Type__c = IntimeConstants.SALESFORCE_TO_INTIME_LEAVER, 
            ErrorMessage__c = ''
        );
        try {
            List<Contact> contactsList = [SELECT Id, InTimeId__c, LeaverInformationUpdatedInInTime__c, LeavingDate__c FROM Contact WHERE Id =: contactId LIMIT 1];
            if (!contactsList.isEmpty() && contactsList[0].LeavingDate__c != null) {
                intimeSyncItem.Person__c = contactsList[0].Id;
                String payload = String.format(
                    IntimeSetting.getLeaverPayload(),
                    new List<String>{
                        IntimeSyncHelper.getToken(),
                        contactsList[0].InTimeId__c,
                        DateTime.newInstance(contactsList[0].LeavingDate__c,Time.newInstance(0,0,0,0)).format('yyyy-MM-dd',UserInfo.getTimezone().getID())+'T00:00:00.000Z'
                    }
                );
                this.intimeSyncLog = 'MakeLeaverById is \r\n\r\n'+payload;
                // calling webserice 
                HttpResponse httpResponse = IntimeWebservice.makeLeaverById(payload);
                this.intimeSyncLog += '\r\n\r\nMakeLeaverById Response is \r\n\r\n'+httpResponse.getBody();

                if (httpResponse.getStatusCode() == 200) {
                    // get the response
                    Object leaverResponse = IntimeWebserviceParser.getFetchResponse(
                        httpResponse.getBody(),
                        'makeLeaverByIdResponse'
                    );
                    contactsList[0].LeaverInformationUpdatedInInTime__c = Boolean.valueOf(leaverResponse);
                    intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS;
                } else {
                    intimeSyncItem.ErrorMessage__c = IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                    intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
                }
                intimeSyncItem.InTimeSyncLog__c = this.intimeSyncLog;
                update contactsList;
                insert intimeSyncItem;
            }
        }catch(Exception ex) {
            intimeSyncItem.InTimeSyncLog__c = this.intimeSyncLog;
            intimeSyncItem.ErrorMessage__c = ex.getMessage();
            intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
            insert intimeSyncItem;
        }
        return intimeSyncItem;
    }
}