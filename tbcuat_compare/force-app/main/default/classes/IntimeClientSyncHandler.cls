/**
*  @description Apex class to manage the account data sync to intime
**/
public with sharing class IntimeClientSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{
    
    private sObject record;
    
    /**
    *  @description Constructor
    **/
    public IntimeClientSyncHandler() {
        super();
    }

    /**
    *  @description Method to trigger the intime sync
    **/
    public void syncToIntime(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        try {
            this.setIntimeSyncItems(inTimeSyncItemsList);
            this.resetIntimeSyncItems();
            // fetch record from the system
            this.getRecords(this.getRecordIds(inTimeSyncItemsList), inTimeObject);

            this.record = !this.recordsList.isEmpty() ? this.recordsList[0] : null;

            // fetch client from intime
            this.fetchClientFromInTime(inTimeSyncItemsList[0], inTimeObject);

            //create or update client in intime 
            String clientId = createOrUpdateClient(inTimeSyncItemsList[0], inTimeObject);
            if (!String.isBlank(clientId)) this.recordsList[0].put(Account.InTimeId__c.getDescribe().getName(),clientId);

            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_CLIENT);
            this.updateRecords();
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_CLIENT);
        }
    }

    /**
    *  @description Method to get additional fields to query for processing
    **/
    public override Set<String> getAdditionalFields() {
        Set<String> additionalFieldsList = new Set<String>{Account.InTimeManagerId__c.getDescribe().getName()};
        if (IntimeSyncHelper.intimeObjectsByObjectNameMap.containsKey(IntimeConstants.INTIME_OBJECT_MANAGER)) {
            additionalFieldsList.addAll(getFieldsList(IntimeSyncHelper.intimeObjectsByObjectNameMap.get(IntimeConstants.INTIME_OBJECT_MANAGER)));
        }
        return additionalFieldsList;
    }

    /**
    *  @description Method to fetch client record from intime
    **/
    private void fetchClientFromInTime(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        // fetch record from intime system
        if (this.record != null && this.record.get(intimeObjectPayload.IntimeFieldReference__c) != null) {
            List<String> recordValuesList = new List<String>{this.intimeToken,String.valueOf(this.record.get(intimeObjectPayload.IntimeFieldReference__c))};
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c = intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
            // calling webserice 
            HttpResponse httpResponse = IntimeWebservice.getRecord(intimeObjectPayload,recordValuesList);
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();

            if (httpResponse.getStatusCode() == 200) {
                // get the response
                Object clientRecord = IntimeWebserviceParser.getFetchResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                if (clientRecord == null || clientRecord instanceof String) {
                    this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\nClient Record doesn\'t exists in Intime';
                } else if (clientRecord instanceof Map<String, Object>) {
                    this.hasRecordExistsInIntime = true; 
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                        IntimeWebserviceParser.getFetchResponse(
                            httpResponse.getBody(),
                            intimeObjectPayload.ResponseElementName__c
                        )
                    ));
                    this.objectsMap.get(inTimeSyncItem.SourceRecordId__c).putAll(responseMap);
                }
            } else {
                this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.errorMap.put(inTimeSyncItem.SourceRecordId__c, true);
            }
        }
    }

    /**
    *  @description Method to create or update client in intime
    **/
    private String createOrUpdateClient(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        String clientId = '';
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
        this.context = this.record.get(Account.InTimeId__c.getDescribe().getName()) != null || this.hasRecordExistsInIntime ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
        //create intime object
        this.objectsMap.get(inTimeSyncItem.SourceRecordId__c).putAll(IntimeSyncHelper.createIntimeObject(inTimeObject, this.record, this.context));

        XMLSerializer serializer = new XMLSerializer('ns');
        String xmlBody = serializer.JSONToXML(JSON.serialize(this.objectsMap.get(inTimeSyncItem.SourceRecordId__c)),true);
        List<String> recordValuesList = new List<String>{this.intimeToken,xmlBody};

        //Placement record
        this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
        HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
        this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();

        if (httpResponse.getStatusCode() == 200) {
            clientId = String.valueOf(IntimeWebserviceParser.getCreateOrUpdateResponse(
                httpResponse.getBody(),
                intimeObjectPayload.ResponseElementName__c
            ));
        } else {
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
            this.errorMap.put(inTimeSyncItem.SourceRecordId__c, true);
        }
        return clientId;
    }
}