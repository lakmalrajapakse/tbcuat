/**
* @description Scheduler used to send the financial tags from salesforce
**/
global with sharing class IntimeFinancialTagSendScheduler implements Schedulable,Database.AllowsCallouts{
    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {
        Set<String> payloadTypesList = new Set<String>{IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_GROUP_CODE_SUBMIT};
        if (!Test.isRunningTest()) payloadTypesList.add(IntimeConstants.INTIME_OBJECT_PAYLOAD_TYPE_CUSTOMER_CODE_SUBMIT);
        Database.executeBatch(new IntimeFinancialTagSendBatch(payloadTypesList),1);
    }
}