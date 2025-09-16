/**
*  @description Apex class to manage the Intime Holiday Sync Handler
**/
public with sharing class IntimeHolidayClaimSyncHandler extends IntimeSyncHandler implements IIntimeSyncHandler{
    
    private sObject record;

    /**
    *  @description Constructor
    **/
    public IntimeHolidayClaimSyncHandler() {
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

            //create or update client in intime 
            String holidayClaimId = createOrUpdateHolidayClaim(inTimeSyncItemsList[0], inTimeObject);
            if (!String.isBlank(holidayClaimId)) this.recordsList[0].put(sirenum__Employee_Request__c.InTimeId__c.getDescribe().getName(),holidayClaimId);

            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_EMPLOYEE_REQUEST);
            this.updateRecords();
        }catch(Exception ex){
            for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
                intimeSyncItem.ErrorMessage__c =  JSON.serialize(ex.getMessage());
                intimeSyncItem.InTimeSyncLog__c += '\r\n\r\n'+'Error is '+'\r\n\r\n'+JSON.serialize(ex.getMessage());
                this.errorMap.put(intimeSyncItem.SourceRecordId__c,true);
            }
            this.updateInTimeSyncItems(IntimeConstants.SALESFORCE_TO_INTIME_EMPLOYEE_REQUEST);
        }
    }

    /**
    *  @description Method to create or update client in intime
    **/
    private String createOrUpdateHolidayClaim(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        String holidayClaimId = '';
        IntimeObjectPayload__mdt intimeObjectPayload = IntimeSyncHelper.getInTimeObjectPayloadByType(inTimeObject,IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_POST);
        this.context = this.record.get(sirenum__Employee_Request__c.InTimeId__c.getDescribe().getName()) != null ? IntimeConstants.INTIME_SYNC_CONTEXT_UPDATE : IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
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
            Map<String, Object> holidayClaimMap = (Map<String, Object>)IntimeWebserviceParser.getCreateOrUpdateResponse(
                httpResponse.getBody(),
                intimeObjectPayload.ResponseElementName__c
            );
            if (holidayClaimMap.containsKey('id')) {
                holidayClaimId = String.valueOf(holidayClaimMap.get('id'));
            }
        } else {
            inTimeSyncItem.ErrorMessage__c =  IntimeSyncHelper.getErrorMessage(httpResponse.getBody());
        }
        return holidayClaimId;
    }
}