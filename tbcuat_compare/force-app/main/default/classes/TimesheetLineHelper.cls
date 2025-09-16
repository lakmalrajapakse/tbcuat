/** 
*  @description : Helper class for timesheet line
**/
public without sharing class TimesheetLineHelper {

    public static List<RateCode__c> rateCodesList;

    static{
        rateCodesList = [SELECT Id, IsOvertime__c, RateModifierType__c, StandardRateType__c, IsDoubleTime__c, IntimePayElement__c FROM RateCode__c];
    }
    
    /** 
    *  @description : Method to manage timesheets
    **/
    public static void manageTimesheetLines(List<sirenum__Timesheet_Line__c> timesheetLinesList, Map<Id, sirenum__Timesheet_Line__c> timesheetLinesMap) {
        Set<Id> tsIds = new Set<Id>();
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            tsIds.add(timesheetLine.sirenum__Timesheet__c);            
        }

        Map<Id, sirenum__Timesheet__c> tsData = new Map<Id, sirenum__Timesheet__c>([select id, sirenum__Week__r.sirenum__Week_Ending__c  from sirenum__Timesheet__c where Id IN :tsIds]);
        
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            Long periodEndDate = DateTime.newInstanceGMT(tsData.get(timesheetLine.sirenum__Timesheet__c).sirenum__Week__r.sirenum__Week_Ending__c, Time.newInstance(0,0,0,0)).getTime();        
            
            timesheetLine.DateUnixEpoch__c = (timesheetLine.sirenum__Date__c != null && DateTime.newInstanceGMT(timesheetLine.sirenum__Date__c,Time.newInstance(0,0,0,0)).getTime() <= periodEndDate) ?
                String.valueOf(DateTime.newInstanceGMT(timesheetLine.sirenum__Date__c,Time.newInstance(0,0,0,0)).getTime()) : String.valueOf(periodEndDate);
        }
    }

    /** 
    *  @description : Method to get rate code
    **/
    public static void manageIntimeRateMappings(List<sirenum__Timesheet_Line__c> timesheetLinesList) {
        Set<Id> rateLineIds = new Set<Id>();
        Set<Id> rateModifierIds = new Set<Id>();
        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
            if (timesheetLine.IntimePayElement__c != null) {
                continue; // Skip lines with IntimePayElement__c set
            }

            if (timesheetLine.sirenum__Rate_Line__c != null) {
                rateLineIds.add(timesheetLine.sirenum__Rate_Line__c);
            }
            if (timesheetLine.sirenum__Rate_Modifier__c != null) {
                rateModifierIds.add(timesheetLine.sirenum__Rate_Modifier__c);
            }
        }

        if (!rateLineIds.isEmpty()) {
            Map<Id, sirenum__Rate_Line__c> rateLinesMap = new Map<Id, sirenum__Rate_Line__c>([SELECT Id, sirenum__Standard_Rate_Type__c FROM sirenum__Rate_Line__c WHERE Id IN: rateLineIds]);
            Map<Id, sirenum__Rate_Modifier__c> rateModifiersMap = new Map<Id, sirenum__Rate_Modifier__c>([SELECT Id, sirenum__Rate_Modifier_Type__c FROM sirenum__Rate_Modifier__c WHERE Id IN: rateModifierIds]);
            for (sirenum__Timesheet_Line__c timesheetLine : timesheetLinesList) {
                setIntimeRateMapping(
                    timesheetLine, 
                    timesheetLine.sirenum__Rate_Line__c != null && rateLinesMap.containsKey(timesheetLine.sirenum__Rate_Line__c) ? rateLinesMap.get(timesheetLine.sirenum__Rate_Line__c) : null, 
                    timesheetLine.sirenum__Rate_Modifier__c != null && rateModifiersMap.containsKey(timesheetLine.sirenum__Rate_Modifier__c) ? rateModifiersMap.get(timesheetLine.sirenum__Rate_Modifier__c) : null
                );
            }
        }
    }

    /** 
    *  @description : Method to get rate code
    **/
    public static void setIntimeRateMapping(sirenum__Timesheet_Line__c timesheetLine, sirenum__Rate_Line__c rateLine, sirenum__Rate_Modifier__c rateModifier) {        
        for (RateCode__c rateCode : rateCodesList) {
            if (((rateCode.IsOvertime__c && timesheetLine.sirenum__RateType__c == 'Overtime') || (!rateCode.IsOvertime__c && timesheetLine.sirenum__RateType__c != 'Overtime'))
                && ((rateCode.IsDoubleTime__c && timesheetLine.sirenum__RateType__c == 'Overtime x2') || (!rateCode.IsDoubleTime__c && timesheetLine.sirenum__RateType__c != 'Overtime x2'))
                && ((rateCode.RateModifierType__c == null && rateModifier == null) || (rateCode.RateModifierType__c != null && rateModifier != null && rateCode.RateModifierType__c == rateModifier.sirenum__Rate_Modifier_Type__c))
                && ((rateCode.StandardRateType__c == null && rateLine == null) || (rateCode.StandardRateType__c != null && rateLine != null && rateCode.StandardRateType__c == rateLine.sirenum__Standard_Rate_Type__c))) {
                timesheetLine.IntimePayElement__c = rateCode.IntimePayElement__c;
                timesheetLine.RateCode__c = rateCode.Id;                
                break;
            }
        }
    }
}