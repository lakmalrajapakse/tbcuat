/** 
*  @description : Helper class for timesheet
**/
public with sharing class TimesheetHelper {

    private static List<String> fieldsAllowedToModifyList = new List<String>{
        sirenum__Timesheet__c.sirenum__PO_Number__c.getDescribe().getName(),
        sirenum__Timesheet__c.LastModifiedbyId.getDescribe().getName(),
        sirenum__Timesheet__c.LastModifiedDate.getDescribe().getName(),
        sirenum__Timesheet__c.InTimeId__c.getDescribe().getName(),
        sirenum__Timesheet__c.InTimeSyncStatus__c.getDescribe().getName(),
        sirenum__Timesheet__c.LastIntimeSync__c.getDescribe().getName(),
        sirenum__Timesheet__c.Timesheet_Type__c.getDescribe().getName(),
        sirenum__Timesheet__c.Adjustment__c.getDescribe().getName(),
        sirenum__Timesheet__c.InTime_Invoice_No__c.getDescribe().getName()
    };

    public static Boolean TIMESHEET_APPROVED_IN_BATCH;

    static {
        InTimeObject__mdt intimeObject = IntimeSyncHelper.getReverseIntimeObject('Timesheet');
        fieldsAllowedToModifyList.addAll(IntimeSyncHelper.getFieldsList(new List<InTimeObject__mdt>{intimeObject}));
        TIMESHEET_APPROVED_IN_BATCH = false;
    }

    /** 
    *  @description : Method to manage timesheets
    **/
    public static void manageTimesheets(List<sirenum__Timesheet__c> timesheetsList, Map<Id, sirenum__Timesheet__c> timesheetsMap) {
        List<InTimeSyncItem__c> intimeSyncItemsToCreate = new List<InTimeSyncItem__c>();
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if ((timesheet.Status__c == IntimeConstants.TIMESHEET_STATUS_APPROVED 
                || timesheet.Status__c == IntimeConstants.TIMESHEET_STATUS_EXPORTED)
                && (timesheet.Status__c != timesheetsMap.get(timesheet.Id).Status__c
                || timesheet.sirenum__PO_Number__c != timesheetsMap.get(timesheet.Id).sirenum__PO_Number__c)) {
                intimeSyncItemsToCreate.add(new InTimeSyncItem__c(
                    Timesheet__c = timesheet.Id,
                    Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_INITIATED
                ));
            }
        }
        if (!intimeSyncItemsToCreate.isEmpty()) {
            insert intimeSyncItemsToCreate;
            if (IntimeSyncHelper.IsInTimeBatchRunning() && !Test.isRunningTest() && !TIMESHEET_APPROVED_IN_BATCH) {
                IntimeSyncProcessor.triggerIntimeRecordProcessorBatch();
            }
        } 
    }

    /** 
    *  @description : Method to calculate weeks for intime
    **/
    public static void calculateIntimeWeeks(List<sirenum__Timesheet__c> timesheetsList, Map<Id, sirenum__Timesheet__c> timesheetsMap) {
        Set<Id> payrollPeriodIds = new Set<Id>();
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            timesheet.WorkYearWeek__c = '';
            timesheet.PayYearWeek__c = '';
            if (timesheet.sirenum__Week__c != null) payrollPeriodIds.add(timesheet.sirenum__Week__c);
        }
        Map<Id, sirenum__Week__c> payrollPeriodMap = new Map<Id, sirenum__Week__c>([SELECT Id, sirenum__Week_Ending__c FROM sirenum__Week__c WHERE Id IN :payrollPeriodIds]);
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if (timesheet.sirenum__Week_Ending__c != null) timesheet.WorkYearWeek__c = IntimeWeekCalculationService.getWeek(timesheet.sirenum__Week_Ending__c);
            if (timesheet.sirenum__Week__c != null && payrollPeriodMap.containsKey(timesheet.sirenum__Week__c) && payrollPeriodMap.get(timesheet.sirenum__Week__c).sirenum__Week_Ending__c != null) timesheet.PayYearWeek__c = IntimeWeekCalculationService.getWeek(payrollPeriodMap.get(timesheet.sirenum__Week__c).sirenum__Week_Ending__c);
        }
    }

    /** 
    *  @description : Method to validate timesheets on update
    **/
    public static void validateTimesheetOnUpdate(List<sirenum__Timesheet__c> timesheetsList, Map<Id, sirenum__Timesheet__c> timesheetsMap) {
        Set<String> modifiedFieldsList = new Set<String>();
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if (!String.isBlank(timesheet.InTimeId__c) && !String.isBlank(timesheetsMap.get(timesheet.Id).InTimeId__c)) {
                for (Schema.sObjectField sObjectField : sirenum__Timesheet__c.sObjectType.getDescribe().fields.getMap().values()) {
                    String fieldName = sObjectField.getDescribe().getName();
                    if (timesheet.get(fieldName) != timesheetsMap.get(timesheet.Id).get(fieldName)) {
                        modifiedFieldsList.add(fieldName);
                    }   
                }
                modifiedFieldsList.removeAll(fieldsAllowedToModifyList);
                if (!modifiedFieldsList.isEmpty()) timesheet.addError('You cannot modify a timesheet that is synced with InTime');
            }
        }
    } 

    /** 
    *  @description : Method to validate timesheets on delete
    **/
    public static void validateTimesheetOnDelete(List<sirenum__Timesheet__c> timesheetsList) {
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if (!String.isBlank(timesheet.InTimeId__c)) {
                timesheet.addError('You cannot delete a timesheet that is synced with InTime');
            }
        }
    }

    /** 
    *  @description : Method to calculate rebates
    **/
    public static void calculateRebates(List<sirenum__Timesheet__c> timesheetsList) {
        Set<Id> timesheetIds = new Set<Id>();
        Map<Id, Account> calculatedRebatedAccountByIdsMap = getCalculatedRebatedClientIds(timesheetsList);
        Map<String, Set<Id>> timesheetIdsByHandlerMap = new Map<String, Set<Id>>();
        Map<Id, Decimal> rebateValueByTimesheetIdMap = new Map<Id, Decimal>();
        if (!calculatedRebatedAccountByIdsMap.isEmpty()) {
            for (sirenum__Timesheet__c timesheet : timesheetsList) {
                if (calculatedRebatedAccountByIdsMap.containsKey(timesheet.sirenum__Client__c) && !String.isBlank(calculatedRebatedAccountByIdsMap.get(timesheet.sirenum__Client__c).Rebate__r.Handler__c)) {
                    String handlerName = calculatedRebatedAccountByIdsMap.get(timesheet.sirenum__Client__c).Rebate__r.Handler__c;
                    if (timesheetIdsByHandlerMap.containsKey(handlerName)) {
                        timesheetIdsByHandlerMap.get(handlerName).add(timesheet.Id);
                    } else {
                        timesheetIdsByHandlerMap.put(handlerName, new Set<Id>{timesheet.Id});
                    }
                }
            }
            for (String handlerName : timesheetIdsByHandlerMap.keySet()) {
                IRebate rebateHandler = (IRebate)Type.forName(handlerName).newInstance();
                rebateValueByTimesheetIdMap.putAll(rebateHandler.calculateRebate(timesheetIdsByHandlerMap.get(handlerName)));
            }
            for (sirenum__Timesheet__c timesheet : timesheetsList) {
                if (rebateValueByTimesheetIdMap.containsKey(timesheet.Id)) {
                    timesheet.RebateAmount__c = rebateValueByTimesheetIdMap.get(timesheet.Id);
                }
            }
        }
    }


    /** 
    *  @description : Method to get the calculated rebate ids
    **/
    public static Map<Id, Account> getCalculatedRebatedClientIds(List<sirenum__Timesheet__c> timesheetsList) {
        Set<Id> clientIds = new Set<Id>();
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            clientIds.add(timesheet.sirenum__Client__c);
        }
        return new Map<Id, Account>([SELECT Id, Rebate__r.Handler__c FROM Account WHERE Id IN :clientIds AND Rebate__r.Type__c = 'Calculated']);
    }   
}