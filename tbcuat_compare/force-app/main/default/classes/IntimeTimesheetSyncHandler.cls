/**
*  @description Apex class to manage the timesheet data sync to intime
**/
public with sharing class IntimeTimesheetSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{

    private List<sObject> expenseRecordsList;
    
    /**
    *  @description Constructor
    **/
    public IntimeTimesheetSyncHandler() {
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

            // set file information
            this.setFileInformation();

            // fetch timesheet from intime
            this.fetchTimeFromInTime(inTimeObject);

            //create or update timesheet in intime 
            createOrUpdateTimesheets(inTimeSyncItemsList, inTimeObject);
            
            // create expense claim
            if (IntimeSyncHelper.intimeObjectsByObjectNameMap.containsKey(IntimeConstants.INTIME_OBJECT_EXPENSE_CLAIM)) {
                createOrUpdateExpenseClaim(inTimeSyncItemsList, IntimeSyncHelper.intimeObjectsByObjectNameMap.get(IntimeConstants.INTIME_OBJECT_EXPENSE_CLAIM));
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET);
            TriggerHandler.bypass(TimesheetTriggerHandler.class.getName());
            this.updateRecords();
            TriggerHandler.clearBypass(TimesheetTriggerHandler.class.getName());
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_TIMESHEET);
        }
    }

    /**
    *  @description Method to get sobject record
    **/
    public override void getRecords(Set<Id> recordIds, InTimeObject__mdt inTimeObject) {
        String contentDocumentQuery = ',(SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FileExtension FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)';
        Set<String> fieldsList = getFieldsList(inTimeObject);
        fieldsList.addAll(getAdditionalFields());
        String soqlQuery = 'SELECT '+String.join(new List<String>(fieldsList),',')+contentDocumentQuery+' FROM '+new List<Id>(recordIds)[0].getSObjectType().getDescribe().getName()+' WHERE Id IN: recordIds';
        this.recordsList = (List<sObject>)Database.query(soqlQuery);
    }

    /**
    *  @description Method to set file information on payload
    **/
    public void setFileInformation() {
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            Map<String, Object> fileObjectMap = new Map<String, Object>();
            if (record.getSObjects('ContentDocumentLinks') != null && record.getSObjects('ContentDocumentLinks').size() > 0) {
                ContentDocumentLink contentDocumentLink = (ContentDocumentLink)record.getSObjects('ContentDocumentLinks')[0];
                fileObjectMap.put('timesheetFileBase64',EncodingUtil.base64Encode(contentDocumentLink.ContentDocument.LatestPublishedVersion.VersionData));
                fileObjectMap.put('timesheetFileName',contentDocumentLink.ContentDocument.Title+'.'+contentDocumentLink.ContentDocument.LatestPublishedVersion.FileExtension);
            }
            this.objectsMap.get(recordId).putAll(fileObjectMap);
        }
    }
    
    /**
    *  @description Method to fetch timesheet record from intime
    **/
    private void fetchTimeFromInTime(InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_FETCH);
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            if (record != null && record.get(intimeObjectPayload.IntimeFieldReference__c) != null) {
                List<String> recordValuesList = new List<String>{this.intimeToken,String.valueOf(record.get(intimeObjectPayload.IntimeFieldReference__c))};
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c = intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                // calling webserice 
                HttpResponse httpResponse = IntimeWebservice.getRecord(intimeObjectPayload,recordValuesList);
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                
                if (httpResponse.getStatusCode() == 200) {
                    // get the response
                    Object timesheetRecord = IntimeWebserviceParser.getFetchResponse(
                        httpResponse.getBody(),
                        intimeObjectPayload.ResponseElementName__c
                    );
                    if (timesheetRecord == null || timesheetRecord instanceof String) {
                        this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\nTimesheet Record doesn\'t exists in Intime';
                    } else if (timesheetRecord instanceof Map<String, Object>) {
                        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(
                            IntimeWebserviceParser.getFetchResponse(
                                httpResponse.getBody(),
                                intimeObjectPayload.ResponseElementName__c
                            )
                        ));
                        this.objectsMap.put(recordId,responseMap);
                    }
                } else {
                    this.intimeSyncItemByRecordIdMap.get(recordId).ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                    this.errorMap.put(recordId, true);
                }
            }
        }
       
    }

    /**
    *  @description Method to create or update timesheet in intime
    **/
    private void createOrUpdateTimesheets(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = null;
        IntimeObjectPayload__mdt intimeObjectCreatePayload = null;
        IntimeObjectPayload__mdt intimeObjectUpdatePayload = null;
        Map<Id, Object> timesheetResultsByIdMap = new Map<Id, Object>();
        List<Object> objectsList = new List<Object>();
        for (sObject record : this.recordsList) {
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,(this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE ? IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_SUBMIT : IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST));
            //create intime object
            this.objectsMap.get(recordId).putAll(IntimeSyncHelper.createIntimeObject(inTimeObject, record, this.context));
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) intimeObjectCreatePayload = intimeObjectPayload;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) intimeObjectUpdatePayload = intimeObjectPayload;
        }

        String xmlBody = '';
        // DO THIS FOR UPDATE CONTEXT
        // UPDATE DOES NOT SUPPORT BULK SUBMISSION
        for (sObject record : this.recordsList) {
            XMLSerializer serializer = new XMLSerializer('ns');
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE) {
                String recordXmlBody = serializer.JSONToXML(JSON.serialize(new Map<String, Object>{'timesheet' => this.objectsMap.get(recordId)}),true);
                List<String> recordValuesList = new List<String>{this.intimeToken,recordXmlBody};
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectUpdatePayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectUpdatePayload.Payload__c,recordValuesList);
                HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectUpdatePayload,recordValuesList);
                System.debug('Body  On Update is '+httpResponse.getBody());
                timesheetResultsByIdMap.putAll(processResponse(new List<Id>{recordId},httpResponse,intimeObjectUpdatePayload));
            }
        }

        // DO THIS FOR CREATE CONTEXT
        // CREATE DOES SUPPORT BULK SUBMISSION
        xmlBody = '';
        List<Id> timesheetIds = new List<Id>();
        for (sObject record : this.recordsList) {
            XMLSerializer serializer = new XMLSerializer('ns');
            Id recordId = (Id)record.get('Id');
            this.context = record.get(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
            if (this.context == IntimeConstants.INTIME_SYNC_CONTEXT_INSERT) {
                timesheetIds.add(recordId);
                String recordXmlBody = serializer.JSONToXML(JSON.serialize(new Map<String, Object>{'timesheets' => this.objectsMap.get(recordId)}),true);
                this.intimeSyncItemByRecordIdMap.get(recordId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectCreatePayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectCreatePayload.Payload__c,new List<String>{this.intimeToken,recordXmlBody});
                xmlBody += recordXmlBody;
            }
        }
        if (!timesheetIds.isEmpty()) {
            List<String> recordValuesList = new List<String>{this.intimeToken,xmlBody};
            //Timesheet record
            HttpResponse httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectCreatePayload,recordValuesList);
            timesheetResultsByIdMap.putAll(processResponse(timesheetIds,httpResponse,intimeObjectCreatePayload));
        }
        
        Map<Id, sObject> recordsMap = new Map<Id, sObject>(this.recordsList);
        System.debug('Map is '+JSON.serialize(recordsMap));
        for (Id timesheetId : timesheetResultsByIdMap.keySet()) {
            Map<String, Object> timeSheetResultMap = (timesheetResultsByIdMap.get(timesheetId) instanceof Map<String, Object>) ? (Map<String, Object>)timesheetResultsByIdMap.get(timesheetId) : (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(timesheetResultsByIdMap.get(timesheetId)));
            if (timeSheetResultMap.containsKey('TIMESHEET_ID')) {
                recordsMap.get(timesheetId).put(sirenum__Timesheet__c.InTimeId__c.getDescribe().getName(),String.valueOf(timeSheetResultMap.get('TIMESHEET_ID')));
            }
            if (timeSheetResultMap.containsKey('RESULT') && String.valueOf(timeSheetResultMap.get('RESULT')).toLowerCase() != 'ok') {
                if (timeSheetResultMap.containsKey('MESSAGE')) {
                    this.intimeSyncItemByRecordIdMap.get(timesheetId).ErrorMessage__c = String.valueOf(timeSheetResultMap.get('MESSAGE'));
                    this.errorMap.put(timesheetId, true);
                }
            }
        }
    }

    /**
    *  @description Method to process the response
    **/
    public Map<Id, Object> processResponse(List<Id> timesheetIds, HttpResponse httpResponse, IntimeObjectPayload__mdt intimeObjectPayload) {
        Map<Id, Object> timesheetResultsByIdMap = new Map<Id, Object>();
        List<Object> timesheetResultsList = new List<Object>();
        if (httpResponse.getStatusCode() == 200) {
            if (timesheetIds.size() == 1) {
                Object timesheeetRecord = IntimeWebserviceParser.getFetchResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                this.intimeSyncItemByRecordIdMap.get(timesheetIds[0]).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+String.valueOf(timesheeetRecord);
                if (timesheeetRecord != null && String.valueOf(timesheeetRecord).startsWith('{')) {
                    timesheetResultsByIdMap.put(timesheetIds[0],timesheeetRecord);
                } else {
                    timesheetResultsByIdMap.put(timesheetIds[0],new Map<String, Object>{'TIMESHEET_ID' => timesheeetRecord});
                }
            } else {
                timesheetResultsList = (List<Object>)IntimeWebserviceParser.getCreateOrUpdateResponse(
                    httpResponse.getBody(),
                    intimeObjectPayload.ResponseElementName__c
                );
                for (Integer i=0;i<timesheetIds.size();i++) {
                    this.intimeSyncItemByRecordIdMap.get(timesheetIds[i]).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+timesheetResultsList[i];
                    timesheetResultsByIdMap.put(timesheetIds[i],timesheetResultsList[i]);
                }
            }
        } else {
            for (Id timesheetId : timesheetIds) { 
                this.intimeSyncItemByRecordIdMap.get(timesheetId).ErrorMessage__c +=  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                this.errorMap.put(timesheetId,true);
            }
        }
        return timesheetResultsByIdMap;
    }

    /**
    *  @description Method to update record
    **/
    public override void updateRecords() {
        for (Integer i=0;i<this.recordsList.size();i++) {
            if (this.errorMap.containsKey((Id)this.recordsList[i].get('Id')) && !this.errorMap.get((Id)this.recordsList[i].get('Id'))) {
                this.recordsList[i].put(sirenum__Timesheet__c.Status__c.getDescribe().getName(),IntimeConstants.TIMESHEET_STATUS_EXPORTED);
            }
            this.recordsList[i].put('LastIntimeSync__c',System.now());
        }
        update this.recordsList;
    }

    /**
    *  @description Method to create or update timesheet in intime
    **/
    private void createOrUpdateExpenseClaim(List<InTimeSyncItem__c> inTimeSyncItemsList, InTimeObject__mdt inTimeObject) {
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
        this.expenseRecordsList = getExpenseRecords(this.getRecordIds(inTimeSyncItemsList), inTimeObject);
        HttpResponse httpResponse = null;
        for (sObject expenseRecord : expenseRecordsList){
            if (!Boolean.valueOf(expenseRecord.get(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName()))) {
                Boolean hasError = false;
                this.context = expenseRecord.get(sirenum__Expense__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
                Id timesheetId = (Id)expenseRecord.get(sirenum__Expense__c.sirenum__Timesheet__c.getDescribe().getName());
                Boolean hasPayChargeSame = expenseRecord.get('ChargeExpenseValue__c') == expenseRecord.get('Expense_value__c');
                List<Object> objectsList = new List<Object>();
                if (hasPayChargeSame) {
                    objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name')), 'value' => (expenseRecord.get('Expense_value__c') != null ? String.valueOf(expenseRecord.get('Expense_value__c')) : '0.00')});
                } else {
                    objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name'))+' PAY', 'value' => (expenseRecord.get('Expense_value__c') != null ? String.valueOf(expenseRecord.get('Expense_value__c')) : '0.00')});
                    objectsList.add(new Map<String, String>{'name' => String.valueOf(expenseRecord.getSObject('sirenum__Expense_Type__r')?.get('Name'))+' CHARGE', 'value' => (expenseRecord.get('ChargeExpenseValue__c') != null ? String.valueOf(expenseRecord.get('ChargeExpenseValue__c')) : '0.00')});
                }
                for (Object expenseObject : objectsList) {
                    intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
                    Map<String, Object> expenseRecordObjectsMap = new Map<String, Object>();
                    if (!this.errorMap.containsKey(timesheetId) || (this.errorMap.containsKey(timesheetId) && !this.errorMap.get(timesheetId))) {
                        if (expenseRecord.getSObjects('ContentDocumentLinks') != null && expenseRecord.getSObjects('ContentDocumentLinks').size() > 0) {
                            ContentDocumentLink contentDocumentLink = (ContentDocumentLink)expenseRecord.getSObjects('ContentDocumentLinks')[0];
                            expenseRecordObjectsMap.put('claimFileBase64',EncodingUtil.base64Encode(contentDocumentLink.ContentDocument.LatestPublishedVersion.VersionData));
                            expenseRecordObjectsMap.put('claimFileName',contentDocumentLink.ContentDocument.Title+'.'+contentDocumentLink.ContentDocument.LatestPublishedVersion.FileExtension);
                        }
                        expenseRecordObjectsMap.putAll(IntimeSyncHelper.createIntimeObject(inTimeObject, expenseRecord, this.context));
                        Map<String, String> expenseObjectMap = (Map<String, String>)expenseObject;
                        for (String expenseObjectMapKey : expenseObjectMap.keySet()) {
                            if (expenseObjectMapKey == 'name') {
                                if (expenseRecordObjectsMap.containsKey('description')) expenseRecordObjectsMap.put('description',expenseObjectMap.get(expenseObjectMapKey));
                                if (expenseRecordObjectsMap.containsKey('expenseItems')) {
                                    List<Object> expenseItems = (List<Object>)expenseRecordObjectsMap.get('expenseItems');
                                    if (!expenseItems.isEmpty()) {
                                        Map<String, Object> expenseItemMap = (Map<String, Object>)expenseItems[0];
                                        if (expenseItemMap.containsKey('payElementCode')) expenseItemMap.put('payElementCode',expenseObjectMap.get(expenseObjectMapKey));
                                        if (expenseItemMap.containsKey('type')) expenseItemMap.put('type',expenseObjectMap.get(expenseObjectMapKey));
                                        if (expenseItemMap.containsKey('description')) expenseItemMap.put('description',expenseObjectMap.get(expenseObjectMapKey));
                                    }
                                }
                            } else if (expenseObjectMapKey == 'value') {
                                if (expenseRecordObjectsMap.containsKey('expenseItems')) {
                                    List<Object> expenseItems = (List<Object>)expenseRecordObjectsMap.get('expenseItems');
                                    if (!expenseItems.isEmpty()) {
                                        Map<String, Object> expenseItemMap = (Map<String, Object>)expenseItems[0];
                                        if (expenseItemMap.containsKey('grossValue')) expenseItemMap.put('grossValue',expenseObjectMap.get(expenseObjectMapKey));
                                    }
                                }
                            }
                        }
                        XMLSerializer serializer = new XMLSerializer('ns');
                        String xmlBody = serializer.JSONToXML(JSON.serialize(expenseRecordObjectsMap),true);
                        List<String> recordValuesList = new List<String>{this.intimeToken,xmlBody};

                        //Sync Log
                        if (this.intimeSyncItemByRecordIdMap.containsKey(timesheetId)) this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                        httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
                        if (this.intimeSyncItemByRecordIdMap.containsKey(timesheetId)) this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                        if (httpResponse.getStatusCode() == 200) {
                            Object expenseClaimId = IntimeWebserviceParser.getCreateOrUpdateResponse(
                                httpResponse.getBody(),
                                intimeObjectPayload.ResponseElementName__c
                            );
                            expenseRecord.put(sirenum__Expense__c.InTimeId__c.getDescribe().getName(),expenseClaimId);
                            expenseRecord.put(sirenum__Expense__c.LastIntimeSync__c.getDescribe().getName(),System.now());

                            // SUBMIT EXPENSE
                            if (expenseClaimId != null && !Boolean.valueOf(expenseRecord.get(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName()))) {
                                intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_SUBMIT);
                                recordValuesList = new List<String>{this.intimeToken,String.valueOf(expenseClaimId)};
                                if (this.intimeSyncItemByRecordIdMap.containsKey(timesheetId)) this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' is \r\n\r\n'+String.format(intimeObjectPayload.Payload__c,recordValuesList);
                                httpResponse = IntimeWebservice.createOrUpdateRecord(intimeObjectPayload,recordValuesList);
                                if (this.intimeSyncItemByRecordIdMap.containsKey(timesheetId)) this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+intimeObjectPayload.MethodName__c.replace('urn:','').capitalize()+' Response is \r\n\r\n'+httpResponse.getBody();
                            }
                        } else {
                            hasError = true;
                            this.intimeSyncItemByRecordIdMap.get(timesheetId).ErrorMessage__c +=  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                            this.intimeSyncItemByRecordIdMap.get(timesheetId).InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
                            this.errorMap.put(timesheetId,true);
                        }
                    }
                }
                if (!hasError) expenseRecord.put(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName(),true);
            }
        }
        update expenseRecordsList;
    }

    /**
    *  @description Method to get sobject record
    **/
    public List<sObject> getExpenseRecords(Set<Id> recordIds, InTimeObject__mdt inTimeObject) {
        String contentDocumentQuery = ',(SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FileExtension FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)';
        Set<String> fieldsList = getFieldsList(inTimeObject);
        fieldsList.addAll(getAdditionalFields());
        fieldsList.add(sirenum__Expense__c.sirenum__Timesheet__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.SubmittedInIntime__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.sirenum__Expense_Type__c.getDescribe().getName().replace('__c','__r')+'.Name');
        fieldsList.add(sirenum__Expense__c.ChargeExpenseValue__c.getDescribe().getName());
        fieldsList.add(sirenum__Expense__c.Expense_value__c.getDescribe().getName());
        String soqlQuery = 'SELECT '+String.join(new List<String>(fieldsList),',')+contentDocumentQuery+' FROM '+sirenum__Expense__c.sObjectType.getDescribe().getName()+' WHERE '+sirenum__Expense__c.sirenum__Timesheet__c.getDescribe().getName()+' IN: recordIds';
        return (List<sObject>)Database.query(soqlQuery);
    }
    
}