global with sharing class SIM_ShiftProcessorOvertime implements sirenum.ShiftProcessorOvertime {
    global SIM_ShiftProcessorOvertime() {
    }

    global Integer getOvertimeBaselineFor(sirenum__Shift__c shift, Datetime startDatetime, sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context) {
        return 0;
    }

    global Object getRelatedData(Datetime startDatetime, Datetime endDatetime, sirenum.ShiftProcessorOvertimeContext context) {
        return null;
    }

    global Set<String> getRequiredFieldPaths(sirenum.ShiftProcessorOvertimeContext context) {
        return new Set<String>{'Name',
                               'sirenum__Team__r.sirenum__Account__r.sirenum__Client__c',                               
                               'sirenum__Billable_Calculated_Start_Time__c',                               
                               'sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c'
                            };
    }

    private static DateTime startOfWeek(sirenum__Shift__c shift) {
        if (shift.sirenum__Billable_Calculated_Start_Time__c == null || shift.sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c == null) {
            return null;
        }

        Integer sday = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(shift.sirenum__Billable_Calculated_Start_Time__c.date()),7);
        Integer pday = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(shift.sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c),7);

        Integer diff = (sday >= pday) ? pday - sday : (pday - sday) - 7;                
        
        return Datetime.newInstance((shift.sirenum__Billable_Calculated_Start_Time__c.date().addDays(diff)), Time.newInstance(0, 0, 0, 0));
    }

    global Datetime getStartOfDayFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
         return null;
    }
    
    global Datetime getStartOfWeekFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
        return startOfWeek(shift);
    }

    global Boolean isNomineeRelevantAsPastWork(sirenum__Shift__c shift, sirenum__Shift__c nominee, 
                                               sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context){    
        return (shift.sirenum__Team__r.sirenum__Account__r.sirenum__Client__c  == nominee.sirenum__Team__r.sirenum__Account__r.sirenum__Client__c) 
          && startOfWeek(shift) == startOfWeek(nominee);
    }
}