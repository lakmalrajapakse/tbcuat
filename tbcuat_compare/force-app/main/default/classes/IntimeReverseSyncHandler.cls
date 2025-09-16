/**
*  @description Method to handle sync from intime to salesforce
**/
public with sharing class IntimeReverseSyncHandler {

    private final Map<String, String> salesforceObjectByIntimeObjectMap = new Map<String, String>{
        'Worker' => 'Contact',
        'Timesheet' => 'sirenum__Timesheet__c'
    };
    private sObject record;
    private String intimeSyncLog;
    
    /**
    *  @description Method to update data from intime to salesforce
    **/
    public void syncToSalesforce(Object intimeObjectResponse) {
        InTimeSyncItem__c intimeSyncItem = new InTimeSyncItem__c(IsReverse__c = true);
        try {
            Map<String, Object> intimeObjectsMap = (Map<String, Object>)intimeObjectResponse;
            this.intimeSyncLog = 'Response is \r\n\r\n'+String.valueOf(intimeObjectsMap);
            if (intimeObjectsMap.containsKey('type') && intimeObjectsMap.containsKey('id'))  {

                // Fetch intime object
                InTimeObject__mdt intimeObject = IntimeSyncHelper.getReverseIntimeObject(String.valueOf(intimeObjectsMap.get('type')));

                // fetch salseforce record
                fetchRecord(String.valueOf(intimeObjectsMap.get('id')), String.valueOf(intimeObjectsMap.get('type')));

                // get record from intime
                Map<String, Object> responseMap = fetchRecordFromInTime(intimeObject, String.valueOf(intimeObjectsMap.get('id')));

                // set salseforce fields
                setSalesforceFields(intimeObject, responseMap);

                intimeSyncItem.InTimeSyncLog__c = this.intimeSyncLog;
                if (String.valueOf(intimeObjectsMap.get('type')) == 'Worker') {
                    intimeSyncItem.Person__c = this.record.Id;
                } else if(String.valueOf(intimeObjectsMap.get('type')) == 'Timesheet'){
                    intimeSyncItem.Timesheet__c	 = this.record.Id;
                }

                // update record
                update this.record;
                intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS;
                insert intimeSyncItem;
            }
        }catch(Exception ex) {
            intimeSyncItem.InTimeSyncLog__c = this.intimeSyncLog;
            intimeSyncItem.ErrorMessage__c = ex.getMessage();
            intimeSyncItem.Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
            insert intimeSyncItem;
        }
    }

    /**
    *  @description Method to fetch worker record from intime
    **/
    private void fetchRecord(String intimeId, String type) {
        List<sObject> recordsList = (List<sObject>)Database.query('SELECT Id FROM '+this.salesforceObjectByIntimeObjectMap.get(type)+' WHERE InTimeId__c = \''+intimeId+'\' LIMIT 1');
        if (!recordsList.isEmpty()) {
            this.record = recordsList[0];
        }
    }

    /**
    *  @description Method to fetch worker record from intime
    **/
    private Map<String, Object> fetchRecordFromInTime(InTimeObject__mdt inTimeObject, String intimeId) {
        Map<String, Object> responseMap;
        String intimeToken = IntimeSyncHelper.getToken();
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        // fetch record from intime system
        if (this.record != null) {
            List<String> recordValuesList = new List<String>{intimeToken,intimeId};
            this.intimeSyncLog += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
            // calling webserice 
            HttpResponse httpResponse = IntimeWebservice.getRecord(intimeObjectPayload,recordValuesList);
            this.intimeSyncLog += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();

            if (httpResponse.getStatusCode() == 200) {
                // get the response
                Object intimeRecord  = IntimeWebserviceParser.getFetchResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                if (intimeRecord instanceof Map<String, Object>) {
                    responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                        IntimeWebserviceParser.getFetchResponse(
                            httpResponse.getBody(),
                            intimeObjectPayload.ResponseElementName__c
                        )
                    ));
                }
            }
        }
        return responseMap;
    }

    /**
    *  @description Method to fetch worker record from intime
    **/
    private void setSalesforceFields(InTimeObject__mdt inTimeObject, Map<String, Object> responseMap) {
        for (InTimeFieldMapping__mdt intimeFieldMapping : inTimeObject.InTimeFieldMappings__r) {
            if (responseMap.containsKey(intimeFieldMapping.InTimeField__c) && responseMap.get(intimeFieldMapping.InTimeField__c) != null && !String.isBlank(String.valueOf(responseMap.get(intimeFieldMapping.InTimeField__c)))) {
                if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECTSLIST) {
                    Map<String, List<Object>> objectsListByFieldNameMap = new Map<String, List<Object>>();
                    List<Object> objectsList = (List<Object>)responseMap.get(intimeFieldMapping.InTimeField__c);
                    if (IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.containsKey(intimeFieldMapping.RelatedObject__c)) {
                        for (Object intimeObjectData : objectsList) {
                            Map<String, Object> intimeObjectMap = (Map<String, Object>)intimeObjectData;
                            for (InTimeFieldMapping__mdt intimeChildObjectFieldMapping : IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.get(intimeFieldMapping.RelatedObject__c).InTimeFieldMappings__r) {
                                if (objectsListByFieldNameMap.containsKey(intimeChildObjectFieldMapping.SalesforceField__c)) {
                                    objectsListByFieldNameMap.get(intimeChildObjectFieldMapping.SalesforceField__c).add(IntimeSyncHelper.getValue(
                                        intimeChildObjectFieldMapping,
                                        intimeObjectMap.get(intimeChildObjectFieldMapping.InTimeField__c)
                                    ));
                                } else {
                                    objectsListByFieldNameMap.put(intimeChildObjectFieldMapping.SalesforceField__c,new List<Object>{IntimeSyncHelper.getValue(
                                        intimeChildObjectFieldMapping,
                                        intimeObjectMap.get(intimeChildObjectFieldMapping.InTimeField__c)
                                    )});
                                }
                            }
                        }
                    }
                    // update the value in record
                    if (!objectsListByFieldNameMap.isEmpty()) {
                        for (String field : objectsListByFieldNameMap.keySet()) {
                            this.record.put(field,String.join(objectsListByFieldNameMap.get(field),','));
                        }
                    }
                } else {
                    this.record.put(intimeFieldMapping.SalesforceField__c, IntimeSyncHelper.getValue(
                        intimeFieldMapping,
                        responseMap.get(intimeFieldMapping.InTimeField__c)
                    ));
                }
                
            }
        }
    }
}