/**
*  @description Constants class used to track all fixed field items used in intime sync
**/
public with sharing class IntimeConstants {
    
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECT = 'Object';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DATE = 'Date';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DATETIME = 'DateTime';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_INTEGER = 'Integer';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_DECIMAL = 'Decimal';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_BOOLEAN = 'Boolean';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_STATIC = 'Static';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_OBJECTSLIST = 'ObjectsList';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_LONG = 'Long';
    public static final String INTIME_SYNC_FIELD_MAPPING_FIELD_TYPE_STRING_LIST = 'StringList';

    public static final String INTIME_SYNC_ITEM_STATUS_INITIATED = 'Initiated';
    public static final String INTIME_SYNC_ITEM_STATUS_QUEUED = 'Queued';
    public static final String INTIME_SYNC_ITEM_STATUS_SUCCESS = 'Success';
    public static final String INTIME_SYNC_ITEM_STATUS_FAILED = 'Failed';

    public static final String INTIME_SYNC_STATUS_NOT_SYNCED = 'Not Synced';

    public static final String INTIME_OBJECT_MANAGER = 'Manager';
    public static final String INTIME_OBJECT_EXPENSE_CLAIM = 'sirenum__Expense__c';

    public static final String HTTP_METHOD_POST = 'POST';
    public static final String HTTP_METHOD_GET = 'GET';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_FETCH = 'Fetch';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_POST = 'Post';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_SUBMIT = 'Submit';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_REINSTATE = 'Reinstate';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_GROUP_CODE_SUBMIT = 'Group Code Submit';
    public static final String INTIME_OBJECT_PAYLOAD_TYPE_CUSTOMER_CODE_SUBMIT = 'Customer Code Submit';

    public static final String AYSNC_APEX_JOB_STATUS_HOLDING = 'Holding';
    public static final String AYSNC_APEX_JOB_STATUS_PREPARING = 'Preparing';
    public static final String AYSNC_APEX_JOB_STATUS_PROCESSING = 'Processing';
    public static final String AYSNC_APEX_JOB_STATUS_QUEUED = 'Queued';

    public static final String AYSNC_APEX_JOB_JOB_TYPE_BATCHAPEX = 'BatchApex';

    public static final String TIMESHEET_STATUS_APPROVED = 'Approved';
    public static final String TIMESHEET_STATUS_EXPORTED = 'Exported';
    public static final String TIMESHEET_STATUS_SUBMITTED = 'Submitted';

    public static final String INTIME_OBJECT_SOURCE_SALESFORCE = 'Salesforce';
    public static final String INTIME_OBJECT_SOURCE_INTIME = 'Intime';

    public static final String INTIME_SYNC_CONTEXT_INSERT = 'insert';
    public static final String INTIME_SYNC_CONTEXT_UPDATE = 'update';

    public static final String SALESFORCE_TO_INTIME_CLIENT = 'Salesforce To Intime Client';
    public static final String SALESFORCE_TO_INTIME_WORKER = 'Salesforce To Intime Worker';
    public static final String SALESFORCE_TO_INTIME_PLACEMENT = 'Salesforce To Intime Placement';
    public static final String SALESFORCE_TO_INTIME_TIMESHEET = 'Salesforce To Intime Timesheet';
    public static final String SALESFORCE_TO_INTIME_TIMESHEET_REVERT = 'Salesforce To Intime Timesheet Revert';
    public static final String SALESFORCE_TO_INTIME_EXPENSE_REVERT = 'Salesforce To Intime Expense Revert';
    public static final String SALESFORCE_TO_INTIME_TIMESHEET_FILE = 'Salesforce To Intime Timesheet File';
    public static final String SALESFORCE_TO_INTIME_EMPLOYEE_REQUEST = 'Salesforce To Intime Employee Request';
    public static final String INTIME_TO_SALESFORCE_WORKER = 'Intime To Salesforce Worker';
    public static final String INTIME_TO_SALESFORCE_TIMESHEET = 'Intime To Salesforce Timesheet';
    public static final String SALESFORCE_TO_INTIME_LEAVER = 'Salesforce To Intime Leaver';
    public static final String SALESFORCE_TO_INTIME_HOLIDAY_CLAIM = 'Salesforce To Intime Holiday Claim';
    public static final String SALESFORCE_TO_INTIME_CUSTOMER_CODE = 'Salesforce To Intime Customer Code';
    public static final String SALESFORCE_TO_INTIME_GROUP_CODE = 'Salesforce To Intime Group Code';

    public static final String EMPLOYEE_REQUEST_TYPE_HOLIDAY = 'Holiday';

    public static final String MAXIMUM_RETRY_ERROR = 'Maximum retry threshold limit reached.';
    public static final String INTIME_OBJECT_TIMESHEET_FILE_DEVELOPER_NAME = 'TimesheetFile';
}