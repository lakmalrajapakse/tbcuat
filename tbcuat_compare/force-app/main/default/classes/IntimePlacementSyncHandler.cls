/**
*  @description Apex class to manage the placement data sync to intime
**/
public with sharing class IntimePlacementSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{
    
    private sObject record;

    /**
    *  @description Constructor
    **/
    public IntimePlacementSyncHandler() {
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

            // fetch placement from intime
            this.fetchPlacementFromInTime(inTimeSyncItemsList[0], inTimeObject);

            // remove parent attributes
            this.removeParentAttributes(inTimeSyncItemsList[0], inTimeObject);

            //create or update placement in intime 
            String placementId = createOrUpdatePlacement(inTimeSyncItemsList[0], inTimeObject);
            if (!String.isBlank(placementId)) this.recordsList[0].put(sirenum__Placement__c.InTimeId__c.getDescribe().getName(),placementId);
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_PLACEMENT);
            this.updateRecords();
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_PLACEMENT);
        }
    }

    /**
    *  @description Method to fetch placement record from intime
    **/
    private void fetchPlacementFromInTime(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        // fetch record from intime system
        if (this.record.get(intimeObjectPayload.IntimeFieldReference__c) != null) {
            List<String> recordValuesList = new List<String>{this.intimeToken,String.valueOf(this.record.get(intimeObjectPayload.IntimeFieldReference__c))};
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c = intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
            // calling webserice 
            HttpResponse httpResponse = IntimeWebservice.getRecord(intimeObjectPayload,recordValuesList);
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();

            if (httpResponse.getStatusCode() == 200) {
                // get the response
                Object placementRecord = IntimeWebserviceParser.getFetchResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                if (placementRecord == null || placementRecord instanceof String) {
                    this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).InTimeSyncLog__c += '\r\n\r\nPlacement Record doesn\'t exists in Intime';
                } else if (placementRecord instanceof Map<String, Object>) {
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                        IntimeWebserviceParser.getFetchResponse(
                            httpResponse.getBody(),
                            intimeObjectPayload.ResponseElementName__c
                        )
                    ));
                    if (this.record.get(sirenum__Placement__c.InTimeRateId__c.getDescribe().getName()) == null) {
                        setRateId(responseMap);
                    }
                    this.objectsMap.get(inTimeSyncItem.SourceRecordId__c).putAll(responseMap);
                }
            } else {
                this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.errorMap.put(inTimeSyncItem.SourceRecordId__c, true);
            }
        }
    }

    /**
    *  @description Method to get additional fields to query for processing
    **/
    public override Set<String> getAdditionalFields() {
        Set<String> additionalFieldsList = new Set<String>{};
        additionalFieldsList.add(sirenum__Placement__c.InTimeId__c.getDescribe().getName());
        return additionalFieldsList;
    }

    /**
    *  @description Method to create or update placement in intime
    **/
    private String createOrUpdatePlacement(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        String placementId = '';
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
        this.context = this.record.get(sirenum__Placement__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
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
            placementId = String.valueOf(IntimeWebserviceParser.getCreateOrUpdateResponse(
                httpResponse.getBody(),
                intimeObjectPayload.ResponseElementName__c
            ));
            this.record.put(sirenum__Placement__c.InTimeId__c.getDescribe().getName(),placementId);
        } else {
            this.intimeSyncItemByRecordIdMap.get(inTimeSyncItem.SourceRecordId__c).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
            this.errorMap.put(inTimeSyncItem.SourceRecordId__c, true);
        }
        return placementId;
    }

    /**
    *  @description Method to create or update placement in intime
    **/
    private void setRateId( Map<String, Object> placementDataMap) {
        if (placementDataMap.containsKey('rates')) {
            Map<String, Object> rateDataMap;
            if (placementDataMap.get('rates') instanceOf Map<String, Object>) rateDataMap = (Map<String,Object>)placementDataMap.get('rates');
            else if (placementDataMap.get('rates') instanceOf List<Object>) {
                List<Object> objectsList = (List<Object>)placementDataMap.get('rates');
                rateDataMap = (Map<String,Object>)objectsList[0];
            }
            if (rateDataMap.containsKey('id')) {
                this.record.put(sirenum__Placement__c.InTimeRateId__c.getDescribe().getName(),String.valueOf(rateDataMap.get('id')));
            }
        }
    }
}