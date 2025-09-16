/** 
*  @description : Apex class to implement Timesheet Results Listener
**/
public with sharing class TimesheetResultsListenerService extends TimesheetResultsListenerHandler implements ISirenumPlugin{

    /** 
    *  @description : Apex class to implement Timesheet Results Listener
    **/
    public TimesheetResultsListenerService() {
        super();
    }

    /** 
    *  @description : Method to process the records
    **/
    public void processRecords(Set<Id> timesheetIds) {
        List<Timesheet> timesheetsList = new List<Timesheet>();
        List<sirenum__Timesheet_Line__c> timesheetLinesToUpdate = new List<sirenum__Timesheet_Line__c>();
        Set<Id> rateLineIds = new Set<Id>();
        List<sirenum__Timesheet__c> timesheetRecordsList = [SELECT Id, 
            (SELECT Id, sirenum__RateType__c, sirenum__Rate_Line__c, sirenum__Rate__c, sirenum__Charge__c, sirenum__Rate_Modifier__c, sirenum__Hours__c, 
                sirenum__Rate_Modifier__r.sirenum__Rate_Modifier_Type__c FROM sirenum__Timesheet_Lines__r) 
            FROM sirenum__Timesheet__c WHERE Id IN :timesheetIds];
        
        // Loop through timesheets
        for (sirenum__Timesheet__c timesheet : timesheetRecordsList) {
            timesheetsList.add(new Timesheet(timesheet));
            for (sirenum__Timesheet_Line__c timesheetLine : timesheet.sirenum__Timesheet_Lines__r) {
                if (timesheetLine.sirenum__Rate_Line__c != null) rateLineIds.add(timesheetLine.sirenum__Rate_Line__c);
            }
        }

        Map<Id, sirenum__Rate_Line__c> rateLinesMap = new Map<Id, sirenum__Rate_Line__c>(
            [SELECT Id, sirenum__Overtime_Pay_Rate__c, sirenum__Overtime_Charge_Rate__c, 
            (SELECT Id, sirenum__Overtime_Charge_Rate__c, sirenum__Overtime_Pay_Rate__c, sirenum__Rate_Modifier_Type__c FROM sirenum__Rate_Modifiers__r) 
            FROM sirenum__Rate_Line__c WHERE Id IN :rateLineIds]
        );

        for (Timesheet timesheet : timesheetsList) {
            timesheetLinesToUpdate.addAll(timesheet.getOvertimeTimesheetLines(rateLinesMap));
        }
        if (!timesheetLinesToUpdate.isEmpty()) update timesheetLinesToUpdate;
    }
}