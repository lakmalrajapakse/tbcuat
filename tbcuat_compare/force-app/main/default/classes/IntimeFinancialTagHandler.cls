/**
*  @description Method to send financial tags from salesforce to intime
**/
public with sharing class IntimeFinancialTagHandler {

    private String intimeSyncLog;
    
    /**
    *  @description Method to update data from intime to salesforce
    **/
    public void syncToInTime(IntimeObjectPayload__mdt intimeObjectPayload) {
        List<Object> objectsList = new List<Object>();
        InTimeSyncItem__c intimeSyncItem = new InTimeSyncItem__c(
            Type__c = intimeObjectPayload.Type__c == 'Group Code Submit' ? IntimeConstants.SALESFORCE_TO_INTIME_GROUP_CODE : IntimeConstants.SALESFORCE_TO_INTIME_CUSTOMER_CODE
        );
        try {
            String intimeToken = IntimeSyncHelper.getToken();
            Set<String> codesList = new Set<String>();
            List<Account> accountsList = [SELECT Client_Code__c FROM Account WHERE Client_Code__c != null ORDER BY Client_Code__c];
            for (Account account : accountsList) {
                codesList.add(account.Client_Code__c.escapeHtml4());
            }
            for (String clientCode : codesList) {
                objectsList.add(new Map<String,Object>{
                    'label' => clientCode,
		            'value' => clientCode
                });
            }
            XMLSerializer serializer = new XMLSerializer('ns');
            String xmlBody = serializer.JSONToXML(JSON.serialize(new Map<String, Object>{'tagCategoryValues' => objectsList}),true);
            List<String> recordValuesList = new List<String>{intimeToken,xmlBody};
            this.intimeSyncLog = intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
            HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
            this.intimeSyncLog += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();


            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.allowFieldTruncation = true;
            intimeSyncItem.setOptions(dmlOptions);
            
            // create intime sync item
            intimeSyncItem.InTimeSyncLog__c = intimeSyncLog;
            intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS;
            insert intimeSyncItem;
        }catch(Exception ex) {
            System.debug('Error is '+ex.getMessage());
            intimeSyncItem.InTimeSyncLog__c = this.intimeSyncLog;
            intimeSyncItem.ErrorMessage__c = ex.getMessage();
            intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
            insert intimeSyncItem;
        }
        if (this.intimeSyncLog.length() > 131070 || Test.isRunningTest()) createContentVersion(intimeSyncItem);
    }

    /**
    *  @description Method to update data from intime to salesforce
    **/
    private void createContentVersion(InTimeSyncItem__c intimeSyncItem){
        ContentVersionCreatorHelper.createContentVersionsAndContentDocumentLinks(new List<ContentVersionCreator>{
            ContentVersionCreatorHelper.createContentVersionCreator(
                this.intimeSyncLog,
                intimeSyncItem.Id, 
                intimeSyncItem.Type__c+' Send Log',
                'txt'
            )
        });
    }
}