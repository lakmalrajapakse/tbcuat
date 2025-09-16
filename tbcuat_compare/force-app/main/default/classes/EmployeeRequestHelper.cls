/**
* @description Helper class for employee request
**/
public with sharing class EmployeeRequestHelper {
    
    /** 
    *  @description : Method to manage timesheets
    **/
    public static void manageEmployeeRequests(List<sirenum__Employee_Request__c> employeeRequestList) {
        Decimal numberOfHoursInADay = IntimeSetting.getHolidayHoursInADay();
        for (sirenum__Employee_Request__c employeeRequest : employeeRequestList) {
            Decimal numberOfHours = 0.00;
            if (employeeRequest.sirenum__Start_Time__c != null && employeeRequest.sirenum__End_Time__c != null) {
                numberOfHours = (Decimal.valueOf(((employeeRequest.sirenum__End_Time__c.getTime() - employeeRequest.sirenum__Start_Time__c.getTime()) / 1000) / 60) / 60).setScale(2);
            }
            employeeRequest.NumberOfHours__c = numberOfHours == 0.00 || employeeRequest.sirenum__All_Day__c || numberOfHours > numberOfHoursInADay ? numberOfHoursInADay : numberOfHours;
            employeeRequest.Intime_Comments__c = employeeRequest.NumberOfHours__c +' hours requested';
        }   
    }

    /** 
    *  @description : Method to manage timesheets
    **/
    public static void manageEmployeeRequests(List<sirenum__Employee_Request__c> employeeRequestList, Map<Id, sirenum__Employee_Request__c> employeeRequestsMap) {
        Set<Id> contactIds = new Set<Id>();
        List<InTimeSyncItem__c> intimeSyncItemsToCreate = new List<InTimeSyncItem__c>();
        for (sirenum__Employee_Request__c employeeRequest : employeeRequestList) {
            if (employeeRequest.sirenum__Type__c == IntimeConstants.EMPLOYEE_REQUEST_TYPE_HOLIDAY && employeeRequest.SendToIntime__c && (employeeRequestsMap == null || 
                (employeeRequestsMap != null && employeeRequest.SendToIntime__c != employeeRequestsMap.get(employeeRequest.Id).SendToIntime__c))) {
                contactIds.add(employeeRequest.sirenum__Contact__c);
            }
        }
        if (!contactIds.isEmpty()) {            
            for (sirenum__Employee_Request__c employeeRequest : employeeRequestList) {
                if (employeeRequest.sirenum__Type__c == IntimeConstants.EMPLOYEE_REQUEST_TYPE_HOLIDAY && (employeeRequestsMap == null || 
                    (employeeRequestsMap != null && employeeRequest.SendToIntime__c != employeeRequestsMap.get(employeeRequest.Id).SendToIntime__c))                    
                    && employeeRequest.sirenum__Approved__c){
                    intimeSyncItemsToCreate.add(new InTimeSyncItem__c(
                        EmployeeRequest__c = employeeRequest.Id,
                        Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED
                    ));
                }
            }
            if (!intimeSyncItemsToCreate.isEmpty()) {
                insert intimeSyncItemsToCreate;
                if (IntimeSyncHelper.IsInTimeBatchRunning() && !Test.isRunningTest()) {
                    IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
                }
            } 
        }
        
    }
}