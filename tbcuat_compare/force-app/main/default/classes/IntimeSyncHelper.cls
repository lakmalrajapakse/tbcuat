/**
*  @description Helper class for Intime sync
**/
public with sharing class IntimeSyncHelper {

    public static Map<Id, InTimeObject__mdt> intimeObjectsByInTimeObjectIdMap;
    public static Map<String, InTimeObject__mdt> intimeObjectsByObjectNameMap;
    private static Map<String, String> intimeFieldNamesByObjectNameMap;
    private static Map<String, String> fieldNameByObjectNameMap;

    static {
        intimeObjectsByObjectNameMap = new Map<String, InTimeObject__mdt>();
        intimeObjectsByInTimeObjectIdMap = getIntimeObjectsByInTimeObjectIdMap();
        fieldNameByObjectNameMap = new Map<String, String>{
            Account.sObjectType.getDescribe().getName() => Account.InTimeId__c.getDescribe().getName(),
            Contact.sObjectType.getDescribe().getName() => Contact.InTimeId__c.getDescribe().getName(),
            sirenum__Placement__c.sObjectType.getDescribe().getName() => sirenum__Placement__c.InTimeId__c.getDescribe().getName()
        };
        intimeFieldNamesByObjectNameMap = new Map<String, String>{
            Account.sObjectType.getDescribe().getName() => InTimeSyncItem__c.Client__c.getDescribe().getName(),
            Contact.sObjectType.getDescribe().getName() => InTimeSyncItem__c.Person__c.getDescribe().getName(),
            sirenum__Placement__c.sObjectType.getDescribe().getName() => InTimeSyncItem__c.Placement__c.getDescribe().getName(),
            sirenum__Timesheet__c.sObjectType.getDescribe().getName() => InTimeSyncItem__c.Timesheet__c.getDescribe().getName() 
        };
    }
    
    /**
    * @description Method to get field value
    **/
    public static Object getValue(InTimeFieldMapping__mdt intimeFieldMapping, Object value) {
        Object formattedValue = null;
        if (value != null) {
            if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DATE) {
                String dateTimeStringValue = String.valueOf(value);
                Datetime dateTimeValue = DateTime.valueOfGMT(dateTimeStringValue);
                formattedValue = !String.isBlank(dateTimeStringValue) ? dateTimeValue.format('yyyy-MM-dd',UserInfo.getTimezone().getID())+'T00:00:00.000Z' : null;
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DATETIME) {
                String dateTimeStringValue = String.valueOf(value);
                Datetime dateTimeValue = DateTime.valueOfGMT(dateTimeStringValue);
                formattedValue = !String.isBlank(dateTimeStringValue) ? dateTimeValue.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',UserInfo.getTimezone().getID()) : null;
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_INTEGER) {
                formattedValue = Integer.valueOf(String.valueOf(value));
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DECIMAL) {
                formattedValue = Decimal.valueOf(String.valueOf(value));
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_BOOLEAN) {
                formattedValue = Boolean.valueOf(String.valueOf(value));
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_LONG) {
                formattedValue = Long.valueOf(String.valueOf(value));
            } else if (intimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_STRING_LIST) {
                formattedValue = value != null ? String.valueOf(value).split(';') : new List<String>();
            } else {
                formattedValue = String.valueOf(value);
            }
        }
        return formattedValue;
    }

    /**
    * @description Method to create an instance of an webservice object
    **/
    public static Map<String, Object> createIntimeObject(InTimeObject__mdt intimeObjectRecord, sObject record, String context) {
        Map<String, Object> objectsMap = new Map<String, Object>();
        // Loop through each field mapping
        for (InTimeFieldMapping__mdt inTimeFieldMapping : intimeObjectRecord.InTimeFieldMappings__r) {
            if ((context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT && inTimeFieldMapping.Insert__c) || (context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE && inTimeFieldMapping.Update__c)) {
                if (inTimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECT) {
                    Map<String, Object> childObjectMap = new Map<String, Object>();
                    childObjectMap.putAll(createIntimeObject(intimeObjectsByInTimeObjectIdMap.get(inTimeFieldMapping.RelatedObject__c), record, context));
                    objectsMap.put(inTimeFieldMapping.InTimeField__c,(Object)childObjectMap);
                } else if (inTimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECTSLIST) {
                    List<Object> objectsList = new List<Object>();
                    Map<String, Object> childObjectMap = new Map<String, Object>();
                    if (!String.isBlank(inTimeFieldMapping.RelatedObject__r.RelationshipName__c)) {
                        for (sObject childRecord : record.getSObjects(inTimeFieldMapping.RelatedObject__r.RelationshipName__c)) {
                            objectsList.add((Object)createIntimeObject(intimeObjectsByInTimeObjectIdMap.get(inTimeFieldMapping.RelatedObject__c), childRecord, context));
                        }
                    } else {
                        childObjectMap.putAll(createIntimeObject(intimeObjectsByInTimeObjectIdMap.get(inTimeFieldMapping.RelatedObject__c), record, context));
                        objectsList.add((Object)childObjectMap);
                    }
                    objectsMap.put(inTimeFieldMapping.InTimeField__c,objectsList);
                } else {
                    objectsMap.put(inTimeFieldMapping.InTimeField__c,getValue(inTimeFieldMapping, getFieldValue(inTimeFieldMapping, record)));
                }
            }
        }
        return objectsMap;
    }

    /**
    * @description Method to get field value
    **/
    public static Object getFieldValue(InTimeFieldMapping__mdt intimeFieldMapping, sObject record) {
        Object fieldValue = '';
        String fieldName = intimeFieldMapping.SalesforceField__c;
        if (!String.isBlank(fieldName)) {
            List<String> fieldNamesList = fieldName.split('\\.');
            if (fieldNamesList.size() == 5) {
                fieldValue = record?.getSObject(fieldNamesList[0])?.getSObject(fieldNamesList[1])?.getSObject(fieldNamesList[2])?.getSObject(fieldNamesList[3])?.get(fieldNamesList[4]);
            } else if (fieldNamesList.size() == 4) {
                fieldValue = record?.getSObject(fieldNamesList[0])?.getSObject(fieldNamesList[1])?.getSObject(fieldNamesList[2])?.get(fieldNamesList[3]);
            } else if (fieldNamesList.size() == 3) {
                fieldValue = record?.getSObject(fieldNamesList[0])?.getSObject(fieldNamesList[1])?.get(fieldNamesList[2]);
            } else if (fieldNamesList.size() == 2) {
                fieldValue = record?.getSObject(fieldNamesList[0])?.get(fieldNamesList[1]);
            } else {
                fieldValue = record.get(fieldNamesList[0]);
            }
        } else if (!String.isBlank(intimeFieldMapping.StaticValue__c)) {
            fieldValue = intimeFieldMapping.StaticValue__c;
        }
       
        return fieldValue;
    }

    /**
    * @description Method to get intime objects by in time object id map 
    **/
    public static Map<Id, InTimeObject__mdt> getIntimeObjectsByInTimeObjectIdMap() {
        Map<Id, InTimeObject__mdt> intimeObjectsByInTimeObjectIdMap = new Map<Id, InTimeObject__mdt>([SELECT Id, Object__c, RelationshipName__c,
        (SELECT Id, IntimeFieldReference__c, MethodName__c, Payload__c, ResponseElementName__c, Type__c FROM IntimeObjectPayload__r),
        (SELECT Id, FieldType__c, StaticValue__c, InTimeField__c, RelatedObject__c, SalesforceField__c, Insert__c, Update__c,
            RelatedObject__r.RelationshipName__c, RelatedObject__r.Object__c FROM InTimeFieldMappings__r) 
            FROM InTimeObject__mdt]);
        for (InTimeObject__mdt inTimeObject : intimeObjectsByInTimeObjectIdMap.values()){
            intimeObjectsByObjectNameMap.put(inTimeObject.Object__c,inTimeObject);
        }
        return intimeObjectsByInTimeObjectIdMap;
    }

    /**
    * @description Method to get intime token
    **/
    public static String getToken() {
        HttpResponse httpResponse = HttpClient.sendRequest(
            String.format(IntimeSetting.getAuthenticatePayload(),new List<String>{
                IntimeSetting.getAgencyReferenceCode(),
                IntimeSetting.getUsername(),
                IntimeSetting.getPassword()
            }),
            new Map<String,String>{
                'Content-Type' => 'text/xml; charset=utf-8',
                'SOAPAction' => 'urn:authenticate'
            }
        );
        return IntimeWebserviceParser.getAuthenticateToken(httpResponse.getBody());
    }

    /**
    * @description Method to get intime token
    **/
    public static Object getResponse(String responseElementName, String xmlBody) {
        Object response = null;
        XMLSerializer serializer = new XMLSerializer('ns');
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(serializer.XMLToJson(xmlBody));
        if (jsonMap.containsKey('Envelope')) {
            Map<String, Object> envelopeMap = (Map<String, Object>)jsonMap.get('Envelope');
            if (envelopeMap.containsKey('Body')) {
                Map<String, Object> bodyMap = (Map<String, Object>)envelopeMap.get('Body');
                if (bodyMap.containsKey(responseElementName)) {
                    Map<String, Object> responseReturnMap = bodyMap.get(responseElementName) instanceOf Map<String, Object> ? (Map<String, Object>)bodyMap.get(responseElementName) : null;
                    if (responseReturnMap != null && responseReturnMap.containsKey('return')) {
                        response = responseReturnMap.get('return');
                    }
                }
            }
        }
        return response;
    }

    /**
    * @description Method to get modified response
    **/
    public static List<Object> getModifiedResponse(String responseElementName, String xmlBody) {
        List<Object> objectsList = new List<Object>();
        XMLSerializer serializer = new XMLSerializer('ns');
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(serializer.XMLToJson(xmlBody));
        if (jsonMap.containsKey('Envelope')) {
            Map<String, Object> envelopeMap = (Map<String, Object>)jsonMap.get('Envelope');
            if (envelopeMap.containsKey('Body')) {
                Map<String, Object> bodyMap = (Map<String, Object>)envelopeMap.get('Body');
                if (bodyMap.containsKey(responseElementName) && bodyMap.get(responseElementName) instanceof Map<String, Object>) {
                    Map<String, Object> responseMap = (Map<String, Object>)bodyMap.get(responseElementName);
                    if (responseMap.get('return') instanceof Map<String, Object>) {
                        objectsList.add(responseMap.get('return'));
                    } else if (responseMap.get('return') instanceof List<Object>) {
                        for (Object responseObject : (List<Object>)responseMap.get('return')) {
                            objectsList.add(responseObject);
                        }
                    }
                }
            }
        }
        return objectsList;
    }

    /**
    * @description Method to get intime object payload
    **/
    public static IntimeObjectPayload__mdt getInTimeObjectPayloadByType(InTimeObject__mdt inTimeObject, String type) {
        IntimeObjectPayload__mdt intimeObjectPayload = null;
        for (IntimeObjectPayload__mdt intimeObjectPayloadRecord : inTimeObject.IntimeObjectPayload__r) {
            if (intimeObjectPayloadRecord.Type__c == type) {
                intimeObjectPayload = intimeObjectPayloadRecord;
            }
        }
        return intimeObjectPayload;
    }

    /**
    * @description Method to get intime error message
    **/
    public static String getErrorMessage(String xmlBody) {
        String errorMessage = '';
        XMLSerializer serializer = new XMLSerializer('ns');
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(serializer.XMLToJson(xmlBody));
        if (jsonMap.containsKey('Envelope')) {
            Map<String, Object> envelopeMap = (Map<String, Object>)jsonMap.get('Envelope');
            if (envelopeMap.containsKey('Body')) {
                Map<String, Object> bodyMap = (Map<String, Object>)envelopeMap.get('Body');
                if (bodyMap.containsKey('Fault')) {
                    Map<String, Object> faultMap = bodyMap.get('Fault') instanceOf Map<String, Object> ? (Map<String, Object>)bodyMap.get('Fault') : null;
                    if (faultMap != null && faultMap.containsKey('faultstring')) {
                        errorMessage = String.valueOf(faultMap.get('faultstring'));
                    }
                }
            }
        }
        return errorMessage;
    }

    /**
    * @description Method to check if intime sync batch is running
    **/
    public static Boolean IsInTimeBatchRunning() {
        Set<String> runningStatusList = new Set<String>{
            IntimeConstants.AYSNC_APEX_JOB_STATUS_HOLDING,
            IntimeConstants.AYSNC_APEX_JOB_STATUS_PREPARING,
            IntimeConstants.AYSNC_APEX_JOB_STATUS_PROCESSING,
            IntimeConstants.AYSNC_APEX_JOB_STATUS_QUEUED
        };
        return [SELECT COUNT() FROM AsyncApexJob WHERE Status IN: runningStatusList AND (ApexClass.Name =: IntimeRecordProcessorBatch.class.getName()
            OR ApexClass.Name =: IntimeSyncBatch.class.getName()) AND JobType =: IntimeConstants.AYSNC_APEX_JOB_JOB_TYPE_BATCHAPEX LIMIT 1] == 0;
    }

    /**
    * @description Method to check has record exists for sync
    **/
    public static Boolean hasRecordExistsForSync() {
        return [SELECT COUNT() FROM InTimeSyncItem__c WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED LIMIT 1] == 0;
    }


    /**
    * @description Method to get modified items by intime
    **/
    public static List<Object> getModifiedItemsFromIntime() {
        String intimeToken = getToken();
        DateTime dateTimeWhenSyncLastRanSuccessfully = IntimeReverseSyncSetting.getDateTimeWhenSyncLastRanSuccessfully();
        dateTimeWhenSyncLastRanSuccessfully = dateTimeWhenSyncLastRanSuccessfully != null ? dateTimeWhenSyncLastRanSuccessfully.addMinutes(-10) : System.now().addMinutes(-70);
        HttpResponse httpResponse = IntimeWebservice.getModifiedItems(new List<String>{
            intimeToken,
            dateTimeWhenSyncLastRanSuccessfully.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',UserInfo.getTimezone().getID()),
            IntimeSetting.getModifiedItemsType()
        });
        return httpResponse.getStatusCode() == 200 ? getModifiedResponse('getModifiedItemsWithRefCodeByTypeResponse',httpResponse.getBody()) : new List<Object>();
    }

    /**
    * @description Method to get reverse intime object
    **/
    public static InTimeObject__mdt getReverseIntimeObject(String type) {
        InTimeObject__mdt intimeObject = null;
        for (InTimeObject__mdt intimeObjectRecord : IntimeSyncProcessor.getIntimeObjects(IntimeConstants.INTIME_OBJECT_SOURCE_INTIME)) {
            if (intimeObjectRecord.Object__c == type) intimeObject = intimeObjectRecord;
        }
        return intimeObject;
    }

    /**
    * @description Method to create an instance of an webservice object
    **/
    public static Set<String> getFieldsList(List<InTimeObject__mdt> intimeObjectsList) {
        Set<String> fieldsList = new Set<String>();
        for (InTimeObject__mdt intimeObject : intimeObjectsList) {
            for (InTimeFieldMapping__mdt inTimeFieldMapping : intimeObject.InTimeFieldMappings__r) {
                if (!String.isBlank(inTimeFieldMapping.SalesforceField__c)) {
                    if (inTimeFieldMapping.SalesforceField__c.contains('__r.')) {
                        fieldsList.add(inTimeFieldMapping.SalesforceField__c.split('\\.')[0].replace('__r','__c'));
                    } else {
                        fieldsList.add(inTimeFieldMapping.SalesforceField__c);
                    }
                }
            }
        }
        return fieldsList;
    }

    /**
    * @description Method to create an instance of an webservice object
    **/
    public static Map<String, Object> getParentFieldsMap(String sObjectName) {
        Map<String, Object> objectsMap = new Map<String, Object>();
        Set<String> fieldsList = new Set<String>();
        Map<String, Set<InTimeFieldMapping__mdt>> childReleationshipNameByObjectNameMap = new Map<String, Set<InTimeFieldMapping__mdt>>();
        for (InTimeFieldMapping__mdt inTimeFieldMapping : [SELECT Id, SalesforceField__c, ChildReleationshipName__c, ParentObjectName__c, InTimeObject__r.Object__c FROM InTimeFieldMapping__mdt WHERE ParentObjectName__c =: sObjectName]) {
            if (!String.isBlank(inTimeFieldMapping.SalesforceField__c) && inTimeFieldMapping.SalesforceField__c.contains('__r.')) {
                List<String> splittedFieldsList = inTimeFieldMapping.SalesforceField__c.split('\\.');
                fieldsList.add(inTimeFieldMapping.SalesforceField__c.split('\\.')[(splittedFieldsList.size() - 1)]);
                if (childReleationshipNameByObjectNameMap.containsKey(inTimeFieldMapping.ParentObjectName__c)) {
                    childReleationshipNameByObjectNameMap.get(inTimeFieldMapping.ParentObjectName__c).add(inTimeFieldMapping);
                } else {
                    childReleationshipNameByObjectNameMap.put(inTimeFieldMapping.ParentObjectName__c,new Set<InTimeFieldMapping__mdt>{inTimeFieldMapping});
                }
            }
        }
        objectsMap.put('fields',fieldsList);
        objectsMap.put('childReleationship',childReleationshipNameByObjectNameMap);
        return objectsMap;
    }

    /**
    * @description Method to get intime objects for an sobject
    **/
    public static List<InTimeObject__mdt> getIntimeObjectsForAnSobject(String sObjectName) {
        List<InTimeObject__mdt> intimeObjectsList = new List<InTimeObject__mdt>();
        for (InTimeObject__mdt intimeObject : intimeObjectsByInTimeObjectIdMap.values()) {
            if (intimeObject.Object__c == sObjectName) {
                intimeObjectsList.add(intimeObject);
            }
        }
        return intimeObjectsList;
    }

    /**
    * @description Method to create intime sync items for sync
    **/
    public static void validateAndCreateIntimeSyncItems(String sObjectName, String fieldName, List<sObject> recordsList, Map<Id, sObject> oldRecordsMap) {
        List<InTimeSyncItem__c> intimeSyncItemsToCreate = new List<InTimeSyncItem__c>();
        Map<String, Set<String>> recordIdsByObjectNameMap = getIntimeSyncItemsInQueue(new Set<String>{sObjectName});
        Set<String> fieldsList = getFieldsList(getIntimeObjectsForAnSobject(sObjectName));
        fieldsList.removeAll(new Set<String>{'InTimeId__c','InTimeRateId__c'});
        for (sObject record : recordsList) {
            String recordId = String.valueOf(record.get('Id'));
            if ((!recordIdsByObjectNameMap.containsKey(sObjectName) || (recordIdsByObjectNameMap.containsKey(sObjectName) && !recordIdsByObjectNameMap.get(sObjectName).contains(recordId))) 
                && (Test.isRunningTest() || (!fieldNameByObjectNameMap.containsKey(sObjectName) || (fieldNameByObjectNameMap.containsKey(sObjectName) 
                && record.get(fieldNameByObjectNameMap.get(sObjectName)) != null)))){
                Set<Boolean> hasRecordModifiedList = new Set<Boolean>();
                for (String field : fieldsList) {
                    hasRecordModifiedList.add(record.get(field) != oldRecordsMap.get(String.valueOf(record.get('Id'))).get(field));
                }
                if (hasRecordModifiedList.contains(true)) {
                    InTimeSyncItem__c intimeSyncItem = new InTimeSyncItem__c(
                        Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED
                    );
                    intimeSyncItem.put(fieldName, String.valueOf(record.get('Id')));
                    intimeSyncItemsToCreate.add(intimeSyncItem);
                }
            }
        }
        if (!intimeSyncItemsToCreate.isEmpty()) insert intimeSyncItemsToCreate;
    }

    /**
    * @description Method to create intime sync items for sync when parent record items were changed
    **/
    public static void validateAndCreateIntimeSyncItemsForParentRecords(String sObjectName, List<sObject> recordsList, Map<Id, sObject> oldRecordsMap) {
        List<InTimeSyncItem__c> intimeSyncItemsToCreate = new List<InTimeSyncItem__c>();
        Set<String> sobjectNamesList = new Set<String>();
        Map<String, Object> objectsMap = getParentFieldsMap(sObjectName);
        Set<String> fieldsList = (Set<String>)objectsMap.get('fields');
        Map<String, Set<InTimeFieldMapping__mdt>> intimeFieldMappingByObjectNameMap = (Map<String, Set<InTimeFieldMapping__mdt>>)objectsMap.get('childReleationship');
        for (String objectName : intimeFieldMappingByObjectNameMap.keySet()) {
            for (InTimeFieldMapping__mdt intimeFieldMapping : intimeFieldMappingByObjectNameMap.get(sObjectName)) {
                sobjectNamesList.add(intimeFieldMapping.InTimeObject__r?.Object__c);
            }
        }
        Map<String, Set<String>> recordIdsByObjectNameMap = getIntimeSyncItemsInQueue(sobjectNamesList);
        Set<Id> recordIds = new Set<Id>();
        for (sObject record : recordsList) {
            String recordId = String.valueOf(record.get('Id'));
            Set<Boolean> hasRecordModifiedList = new Set<Boolean>();
            for (String field : fieldsList) {
                hasRecordModifiedList.add(record.get(field) != oldRecordsMap.get(String.valueOf(record.get('Id'))).get(field));
            }
            if (hasRecordModifiedList.contains(true)) {
                recordIds.add(recordId);
            }
        }
        if (!recordIds.isEmpty()) {
            String soqlQuery = getSoqlQuery(intimeFieldMappingByObjectNameMap.get(sObjectName),sObjectName);
            List<sObject> queriedRecordsList = (List<sObject>)Database.query(soqlQuery);
            for (sObject record : queriedRecordsList) {
                for (InTimeFieldMapping__mdt intimeFieldMapping : intimeFieldMappingByObjectNameMap.get(sObjectName)) {
                    if (record.getsObjects(intimeFieldMapping.ChildReleationshipName__c) != null) {
                        for (sObject childRecord : record.getsObjects(intimeFieldMapping.ChildReleationshipName__c)) {
                            String childObjectName = intimeFieldMapping.InTimeObject__r?.Object__c;
                            String childRecordId = String.valueOf(childRecord.get('Id'));
                            if ((!recordIdsByObjectNameMap.containsKey(childObjectName) || (recordIdsByObjectNameMap.containsKey(childObjectName) && !recordIdsByObjectNameMap.get(childObjectName).contains(childRecordId)))) {
                                InTimeSyncItem__c intimeSyncItem = new InTimeSyncItem__c(
                                    Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED
                                );
                                intimeSyncItem.put(intimeFieldNamesByObjectNameMap.get(intimeFieldMapping.InTimeObject__r.Object__c), childRecordId);
                                intimeSyncItemsToCreate.add(intimeSyncItem);
                                if (recordIdsByObjectNameMap.containsKey(childObjectName)) {
                                    recordIdsByObjectNameMap.get(childObjectName).add(childRecordId);
                                } else {
                                    recordIdsByObjectNameMap.put(childObjectName, new Set<String>{childRecordId});
                                }
                            }
                        }
                    }
                }
            }
        }
        if (!intimeSyncItemsToCreate.isEmpty()) insert intimeSyncItemsToCreate;
    }

    /**
    * @description Method to get soql quer
    **/
    public static  String getSoqlQuery(Set<InTimeFieldMapping__mdt> intimeFieldMappingsList, String objectName) {
        Set<String> childQueryList = new Set<String>();
        String soqlQuery = 'SELECT Id, ';
        for (InTimeFieldMapping__mdt intimeFieldMapping : intimeFieldMappingsList) {
            childQueryList.add('(SELECT Id FROM '+intimeFieldMapping.ChildReleationshipName__c+' WHERE InTimeId__c != null)');
        }
        soqlQuery += String.join(childQueryList,',');
        soqlQuery += ' FROM '+objectName+' WHERE Id IN: recordIds';
        return soqlQuery;
    }

    /**
    * @description Method to get intime sync item by record map
    **/
    public static  Map<Id, InTimeSyncItem__c> getIntimeSyncItemsByRecordIdMap(List<InTimeSyncItem__c> intimeSyncItemsList) {
        Map<Id, InTimeSyncItem__c> intimeSyncItemByRecordIdMap = new Map<Id, InTimeSyncItem__c>();
        for (InTimeSyncItem__c intimeSyncItem : intimeSyncItemsList) {
            intimeSyncItemByRecordIdMap.put(intimeSyncItem.SourceRecordId__c, intimeSyncItem);
        }
        return intimeSyncItemByRecordIdMap;
    }

    /**
    * @description Method to get intime sync item by record map
    **/
    public static Map<String, Set<String>> getIntimeSyncItemsInQueue(Set<String> sObjectName) {
        Map<String, Set<String>> recordIdsByObjectNameMap = new Map<String, Set<String>>();
        for (InTimeSyncItem__c intimeSyncItem : [SELECT Id, SourceRecordId__c, ObjectType__c FROM InTimeSyncItem__c WHERE ObjectType__c =: sObjectName AND 
            (Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED OR Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED)]) {
            if(recordIdsByObjectNameMap.containsKey(intimeSyncItem.ObjectType__c)) {
                recordIdsByObjectNameMap.get(intimeSyncItem.ObjectType__c).add(intimeSyncItem.SourceRecordId__c);
            } else {
                recordIdsByObjectNameMap.put(intimeSyncItem.ObjectType__c, new Set<String>{intimeSyncItem.SourceRecordId__c});
            }
        }
        return recordIdsByObjectNameMap;
    }

    /**
    * @description Method to get intime sync item by record map
    **/
    public static Set<String> searchHolidayClaimsInIntime(String contactExternalId) {
        Set<String> holidayClaimRefs = new Set<String>();
        String httpResponseBody = '';
        String payload = String.format(
            IntimeSetting.getSearchHolidayClaimPayload(),
            new List<String>{
                IntimeSyncHelper.getToken(),
                contactExternalId
            }
        );
        HttpResponse httpResponse = IntimeWebservice.searchHolidayClaims(payload);
        if (httpResponse.getStatusCode() == 200) {
            Object searchResponse = IntimeWebserviceParser.getFetchResponse(
                httpResponse.getBody(),
                'searchHolidayClaimRefCodesResponse'
            );
            if (searchResponse instanceof String) {
                holidayClaimRefs.add(String.valueOf(searchResponse));
            } else if (searchResponse instanceof List<Object>) {
                for (Object holidayClaimRef : (List<Object>)searchResponse) {
                    holidayClaimRefs.add(String.valueOf(holidayClaimRef));
                }
            }
        }
        return holidayClaimRefs;
    }

    /**
    * @description Method to get intime sync item by record map
    **/
    public static List<Object> getHolidayClaimsFromIntime(Set<String> holidayClaimRefs) {
        List<Object> holidayClaimsList = new List<Object>();
        String httpResponseBody = '';
        String xmlBody = '';
        for (String holidayClaimRef : holidayClaimRefs) {
            xmlBody += '<ns:holidayClaimRefCodes>'+holidayClaimRef+'</ns:holidayClaimRefCodes>';
        }
        String payload = String.format(
            IntimeSetting.getHolidayClaimByRefPayload(),
            new List<String>{
                IntimeSyncHelper.getToken(),
                xmlBody
            }
        );
        HttpResponse httpResponse = IntimeWebservice.getHolidayClaimsByRefs(payload);
        if (httpResponse.getStatusCode() == 200) {
            Object getHolidayClaimResponse = IntimeWebserviceParser.getFetchResponse(
                httpResponse.getBody(),
                'getHolidayClaimsByRefCodesResponse'
            );
            if (getHolidayClaimResponse instanceof Map<String,Object>) {
                holidayClaimsList.add(String.valueOf(getHolidayClaimResponse));
            } else if (getHolidayClaimResponse instanceof List<Object>) {
                holidayClaimsList.addAll((List<Object>)getHolidayClaimResponse);
            }
        }
        return holidayClaimsList;
    }

    /**
    * @description Method to update retry count
    **/
    public static  void updateRetryCount(String objectType) {
        List<InTimeSyncItem__c> intimeSyncItemsList = [SELECT Id, Name, SourceRecordId__c, InTimeSyncLog__c, ObjectType__c, RetryCount__c FROM InTimeSyncItem__c 
            WHERE Status__c =: IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED AND ObjectType__c =: objectType];
        for (InTimeSyncItem__c intimeSyncItem : intimeSyncItemsList) {
            intimeSyncItem.RetryCount__c = intimeSyncItem.RetryCount__c == null ? 1 : (intimeSyncItem.RetryCount__c + 1);
        }
        update intimeSyncItemsList;
    }
    
}