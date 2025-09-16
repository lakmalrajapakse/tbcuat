import Utils from './utils.js';

export default class Shift {
    constructor(record){
        this.Id = record.Id;
        this.shift = record;

        this.shiftDate = Utils.formatDate(record.sirenum__Shift_Date__c);

        this.scheduledStartTime = Utils.formatDate(record.sirenum__Scheduled_Start_Time__c);
        this.scheduledEndTime = Utils.formatDate(record.sirenum__Scheduled_End_Time__c);

        this.actualStartTime = Utils.formatDate(record.sirenum__Actual_Start_Time__c);
        this.actualEndTime = Utils.formatDate(record.sirenum__Actual_End_Time__c);

        this.poNumber = record.PO_Number__c != null ? record.PO_Number__c : record.sirenum__Placement__r?.PO_Number__c;

        this.hasPayOrCharge = record.Pay__c != 0 || record.Charge__c != 0;
        this.isAdhoc = !record.sirenum__Scheduled_End_Time__c;
        this.isPayrolled = !!record.sirenum__Timesheet_summaries__c;

        this.hasBreaks = record?.sirenum__Shift_Breaks__r?.records?.length > 0;
        this.breaks = record?.sirenum__Shift_Breaks__r?.records;
        this.hasExpenses = record?.Expenses__r?.records?.length > 0;
        this.expenses = record?.Expenses__r?.records;

        this.portalHoursEntry  = record.Time_Type__c == 'Hours';

        switch (record?.sirenum__Contract__r?.Approval_Hours_Entry_Type__c) {
            case 'Start + End Time':
                this.crStartEndEntry = true;
                break;
            case 'Hours':
                this.crHoursOnlyEntry = true;
                break;
            case 'Daily':
                this.crDailyEntry = true;
                break;
            default:
                //Default to Start/End Entry  
                this.crStartEndEntry = true;
        }

        switch (record?.sirenum__Contract__r?.Actual_Hours_Entry_Type__c) {
            case 'Start + End Time':
                this.ahStartEndEntry = true;
                break;
            case 'Hours': 		
                this.ahHoursOnlyEntry = true;
                break;
            case 'Daily': 
                this.ahDailyEntry = true;
                break;
            default:
                //Default to Start/End Entry  
                this.ahStartEndEntry = true;
        }

        switch (record?.sirenum__Contract__r?.Billable_Hours_Entry_Type__c) {
            case 'Start + End Time':
                this.pbStartEndEntry = true;
                break;
            case 'Hours': 
                this.pbHoursOnlyEntry = true;
                break;
            case 'Daily':		
                this.pbDailyEntry = true;
                break;
            default:
                //Default to Start/End Entry  
                this.pbStartEndEntry = true;
        }
    }
}