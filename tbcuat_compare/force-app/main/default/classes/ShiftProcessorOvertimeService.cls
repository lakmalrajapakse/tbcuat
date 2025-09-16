/** 
*  @description : Apex class to implement shift processor overtime
**/
public with sharing class ShiftProcessorOvertimeService implements sirenum.ShiftProcessorOvertime{

    /** 
    *  @description : Method to get overtime baseline
    **/
    public Integer getOvertimeBaselineFor(sirenum__Shift__c shift, Datetime startDatetime, sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context) {
        return 0;
    }

    /** 
    *  @description : Method to get related data
    **/
    public Object getRelatedData(Datetime startDatetime, Datetime endDatetime, sirenum.ShiftProcessorOvertimeContext context) {
        return null;
    }

    /**
    *  @description Method to get start of the week for
    **/
    public Datetime getStartOfDayFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
        return null;
    }

    /**
    *  @description Method to get required field paths
    **/
    public Set<String> getRequiredFieldPaths(sirenum.ShiftProcessorOvertimeContext context) {
        return new Set<String>{
            'Name',
            'sirenum__Team__r.sirenum__Account__r.sirenum__Client__c',                               
            'sirenum__Billable_Calculated_Start_Time__c',                               
            'sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c'
        };
    }

    /**
    *  @description Method to get start of the week for
    **/
    public Datetime getStartOfWeekFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
        return startOfWeek(shift);
    }

    /** 
    *  @description : Method to get start of the week
    **/
    public static DateTime startOfWeek(sirenum__Shift__c shift) {
        if (shift.sirenum__Billable_Calculated_Start_Time__c == null || shift.sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c == null) {
            return null;
        }
        Integer sday = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(shift.sirenum__Billable_Calculated_Start_Time__c.date()),7);
        Integer pday = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(shift.sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c),7);
        Integer diff = (sday >= pday) ? pday - sday : (pday - sday) - 7;             
        return Datetime.newInstance((shift.sirenum__Billable_Calculated_Start_Time__c.date().addDays(diff)), Time.newInstance(0, 0, 0, 0));
    }

    /** 
    *  @description : Method to get if nominee relevant as past work
    **/
    public Boolean isNomineeRelevantAsPastWork(sirenum__Shift__c shift, sirenum__Shift__c nominee, sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context){    
        return (shift.sirenum__Team__r.sirenum__Account__r.sirenum__Client__c  == nominee.sirenum__Team__r.sirenum__Account__r.sirenum__Client__c) && startOfWeek(shift) == startOfWeek(nominee);
    }
}