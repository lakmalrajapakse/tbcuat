/** 
*  @description : Wrapper class for timesheet
**/
public with sharing class Timesheet {

    public sirenum__Timesheet__c timesheet;
    private List<sirenum__Timesheet_Line__c> overtimeTimesheetLinesList;
    public Map<Id, Decimal> hoursByRateLineMap;
    private Id rateLineIdWithMostHours;

    /**
    *  @description Constructor
    **/
    public Timesheet(sirenum__Timesheet__c timesheet) {
        this.timesheet = timesheet;
        this.hoursByRateLineMap = new Map<Id, Decimal>();
        this.overtimeTimesheetLinesList = new List<sirenum__Timesheet_Line__c>();
        this.rateLineIdWithMostHours = null;

        // set hours by rate line map
        setHoursByRateLineMap();

        // find raate line id with most hours
        findRateLineWithMostHours();
    }

    /**
    *  @description Method to set hours by rate line map
    **/
    private void setHoursByRateLineMap() {
        for (sirenum__Timesheet_Line__c timesheetLine : this.timesheet.sirenum__Timesheet_Lines__r) {
            if (timesheetLine.sirenum__RateType__c == 'Hourly') {
                if (this.hoursByRateLineMap.containsKey(timesheetLine.sirenum__Rate_Line__c)){
                    this.hoursByRateLineMap.put(timesheetLine.sirenum__Rate_Line__c, (this.hoursByRateLineMap.get(timesheetLine.sirenum__Rate_Line__c) + timesheetLine.sirenum__Hours__c));
                } else {
                    this.hoursByRateLineMap.put(timesheetLine.sirenum__Rate_Line__c, timesheetLine.sirenum__Hours__c);
                }
            } else if(timesheetLine.sirenum__RateType__c == 'Overtime') {
                this.overtimeTimesheetLinesList.add(timesheetLine);
            }
        }
    }

    /**
    *  @description Method to find rate line id with most hours
    **/
    private void findRateLineWithMostHours() {
        List<Decimal> hoursList = new List<Decimal>(this.hoursByRateLineMap.values());
        hoursList.sort();
        for (Id rateLineId : this.hoursByRateLineMap.keySet()) {
            if (hoursList[hoursList.size() - 1] == this.hoursByRateLineMap.get(rateLineId)) {
                this.rateLineIdWithMostHours = rateLineId;
                break;
            }
        }
    }

    /**
    *  @description Method to find rate line id with most hours
    **/
    public List<sirenum__Timesheet_Line__c> getOvertimeTimesheetLines(Map<Id, sirenum__Rate_Line__c> rateLinesMap) {
        if (!this.overtimeTimesheetLinesList.isEmpty() && this.rateLineIdWithMostHours != null && rateLinesMap.containsKey(this.rateLineIdWithMostHours)) {
            for (sirenum__Timesheet_Line__c timesheetLine : this.overtimeTimesheetLinesList) {
                if (timesheetLine.sirenum__Rate_Modifier__c == null) {
                    timesheetLine.sirenum__Rate_Line__c = this.rateLineIdWithMostHours;
                    timesheetLine.sirenum__Rate__c = rateLinesMap.get(this.rateLineIdWithMostHours).sirenum__Overtime_Pay_Rate__c;
                    timesheetLine.sirenum__Charge__c = rateLinesMap.get(this.rateLineIdWithMostHours).sirenum__Overtime_Charge_Rate__c;
                } else {
                    for (sirenum__Rate_Modifier__c rateModifier : rateLinesMap.get(this.rateLineIdWithMostHours).sirenum__Rate_Modifiers__r) {
                        if (rateModifier.sirenum__Rate_Modifier_Type__c == timesheetLine.sirenum__Rate_Modifier__r.sirenum__Rate_Modifier_Type__c) {
                            timesheetLine.sirenum__Rate_Line__c = this.rateLineIdWithMostHours;
                            timesheetLine.sirenum__Rate__c = rateModifier.sirenum__Overtime_Pay_Rate__c;
                            timesheetLine.sirenum__Charge__c = rateModifier.sirenum__Overtime_Charge_Rate__c;
                        }
                    }
                }
            }
        }
        return this.overtimeTimesheetLinesList;
    }

}