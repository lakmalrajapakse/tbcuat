/**
*  @description Apex class to manage core intime sync methods and properties
**/
public virtual with sharing class IntimeSyncHandler {
    
    protected Map<Id, Map<String, Object>> objectsMap;
    protected List<sObject> recordsList;
    protected String intimeToken;
    protected Map<Id,Boolean> errorMap;
    protected Map<Id, InTimeSyncItem__c> intimeSyncItemByRecordIdMap;
    protected String context;
    protected Boolean hasRecordExistsInIntime;
    protected Map<Id, ContentVersionCreator> contentVersionCreatorByIntimeIdMap;

    /**
    *  @description Constructor
    **/
    public IntimeSyncHandler() {
        this.objectsMap = new Map<Id, Map<String, Object>>();
        this.errorMap = new Map<Id,Boolean>();
        this.intimeToken = IntimeSyncHelper.getToken();
        this.hasRecordExistsInIntime = false;
        this.context = IntimeConstants.INTIME_SYNC_CONTEXT_INSERT;
        this.contentVersionCreatorByIntimeIdMap = new Map<Id, ContentVersionCreator>();
    }

    /**
    *  @description Method to populate intime sync item by record id map
    **/
    public void setIntimeSyncItems(List<InTimeSyncItem__c> inTimeSyncItemsList) {
        this.intimeSyncItemByRecordIdMap = IntimeSyncHelper.getIntimeSyncItemsByRecordIdMap(inTimeSyncItemsList);
        for (InTimeSyncItem__c intimeSyncItem : inTimeSyncItemsList) {
            this.objectsMap.put(intimeSyncItem.SourceRecordId__c, new Map<String, Object>());
            this.errorMap.put(intimeSyncItem.SourceRecordId__c, false);
        }
    }
    
    /**
    *  @description Method to get sobject record
    **/
    public virtual void getRecords(Set<Id> recordIds, InTimeObject__mdt inTimeObject) {
        Set<String> fieldsList = getFieldsList(inTimeObject);
        fieldsList.addAll(getAdditionalFields());
        String soqlQuery = 'SELECT '+String.join(new List<String>(fieldsList),',')+' FROM '+new List<Id>(recordIds)[0].getSObjectType().getDescribe().getName()+' WHERE Id IN: recordIds';
        List<sObject> recordsList = (List<sObject>)Database.query(soqlQuery);
        this.recordsList = !recordsList.isEmpty() ? recordsList : new List<sObject>();
    }

    /**
    *  @description Method to get records ids from intime sync items
    **/
    public virtual Set<Id> getRecordIds(List<InTimeSyncItem__c> inTimeSyncItemsList) {
        Set<Id> recordIds = new Set<Id>();
        for (InTimeSyncItem__c intimeSyncItem : inTimeSyncItemsList) {
            if (!String.isBlank(intimeSyncItem.SourceRecordId__c)) recordIds.add(intimeSyncItem.SourceRecordId__c);
        }
        return recordIds;
    }

    /**
    *  @description Method to reset the error message
    **/
    public virtual void resetIntimeSyncItems() {
        for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
            intimeSyncItem.ErrorMessage__c = '';
            intimeSyncItem.InTimeSyncLog__c = '';
        }
    }

    /**
    *  @description Method to get fields list
    **/
    public Set<String> getFieldsList(InTimeObject__mdt inTimeObject) {
        Set<String> fieldsList = new Set<String>();
        for (InTimeFieldMapping__mdt intimeFieldMapping : inTimeObject.InTimeFieldMappings__r) {
            if (inTimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECT || 
                inTimeFieldMapping.FieldType__c == IntimeConstants.INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECTSLIST) {
                if (!String.isBlank(intimeFieldMapping.RelatedObject__r.RelationshipName__c)) {
                    Set<String> childFieldsList = getFieldsList(
                        IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.containsKey(intimeFieldMapping.RelatedObject__c) ? 
                            IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.get(intimeFieldMapping.RelatedObject__c) : new InTimeObject__mdt()
                    );
                    fieldsList.add('(SELECT '+String.join(new List<String>(childFieldsList),',')+' FROM '+intimeFieldMapping.RelatedObject__r.RelationshipName__c+')');
                } else {
                    fieldsList.addAll(getFieldsList(
                        IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.containsKey(intimeFieldMapping.RelatedObject__c) ? 
                            IntimeSyncHelper.intimeObjectsByInTimeObjectIdMap.get(intimeFieldMapping.RelatedObject__c) : new InTimeObject__mdt()
                    ));
                }
                
            } else if (!String.isBlank(intimeFieldMapping.SalesforceField__c)) {
                fieldsList.add(intimeFieldMapping.SalesforceField__c);
            }
        }
        return fieldsList;
    }

    /**
    *  @description Method to get fields list
    **/
    public void removeParentAttributes(InTimeSyncItem__c inTimeSyncItem, InTimeObject__mdt inTimeObject) {
        for (InTimeFieldMapping__mdt intimeFieldMapping : inTimeObject.InTimeFieldMappings__r) {
            if (intimeFieldMapping.RelatedObject__c != null) {
                this.objectsMap.get(inTimeSyncItem.SourceRecordId__c).remove(intimeFieldMapping.InTimeField__c);
            }
        }
    }

    /**
    *  @description Method to get fields list
    **/
    public virtual Set<String> getAdditionalFields() {
        return new Set<String>();
    }

    /**
    *  @description Method to update record
    **/
    public virtual void updateRecords() {
        for (Integer i=0;i<this.recordsList.size();i++) {
            Id recordId = (Id)this.recordsList[0].Id;
            if (this.intimeSyncItemByRecordIdMap != null && this.intimeSyncItemByRecordIdMap.containsKey(recordId) && String.isBlank(this.intimeSyncItemByRecordIdMap.get(recordId).ErrorMessage__c)) {
                this.recordsList[i].put('LastIntimeSync__c',System.now());
            }
        }
        update this.recordsList;
    }

    /**
    *  @description Method to update intime sync items
    **/
    public void updateInTimeSyncItems(String type) {
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.allowFieldTruncation = true;
        for (InTimeSyncItem__c intimeSyncItem : this.intimeSyncItemByRecordIdMap.values()) {
            if ((intimeSyncItem != null && !String.isBlank(intimeSyncItem.InTimeSyncLog__c) && intimeSyncItem.InTimeSyncLog__c.length() > 131070) || Test.isRunningTest()) {
                this.contentVersionCreatorByIntimeIdMap.put(intimeSyncItem.Id, ContentVersionCreatorHelper.createContentVersionCreator(
                    intimeSyncItem.InTimeSyncLog__c,
                    intimeSyncItem.Id, 
                    intimeSyncItem.Name,
                    'txt'
                ));
            }
            if (this.errorMap.containsKey(intimeSyncItem.SourceRecordId__c)) intimeSyncItem.Status__c = !this.errorMap.get(intimeSyncItem.SourceRecordId__c) ? IntimeConstants.INTIME_SYNC_ITEM_STATUS_SUCCESS : IntimeConstants.INTIME_SYNC_ITEM_STATUS_FAILED;
            intimeSyncItem.Type__c = type;
            intimeSyncItem.setOptions(dmlOptions);
        }
        update this.intimeSyncItemByRecordIdMap.values();
        if (!this.contentVersionCreatorByIntimeIdMap.isEmpty()) ContentVersionCreatorHelper.createContentVersionsAndContentDocumentLinks(this.contentVersionCreatorByIntimeIdMap.values());
    }
}