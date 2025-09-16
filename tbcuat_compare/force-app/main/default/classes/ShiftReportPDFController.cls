public class ShiftReportPDFController {
    public Id timesheetId { get; set; }
    public List<sirenum__Shift__c> shifts { get; set; }
    public String payPeriod { get; set; }
    public String siteName { get; set; }
    public String jobName { get; set; }
    public String workerName { get; set; }

    public ShiftReportPDFController() {
        // Retrieve the Timesheet ID and associated shifts
        timesheetId = ApexPages.currentPage().getParameters().get('timesheetId');
        String shiftIdsString = ApexPages.currentPage().getParameters().get('shiftIds');
        
        // Convert the comma-separated string into a List<Id>
        List<Id> shiftIds = new List<Id>();
        
        if (shiftIdsString != null && shiftIdsString != '') {
            shiftIds = shiftIdsString.split(',');
        }
         sirenum__Timesheet__c timesheet=[select id,sirenum__Week__r.sirenum__WeekEndDateFormatted__c,sirenum__Site__r.Name,sirenum__Worker__r.Name,sirenum__Team__r.Name from sirenum__Timesheet__c where id=:timesheetId];
         payPeriod =timesheet.sirenum__Week__r.sirenum__WeekEndDateFormatted__c;
         siteName = timesheet.sirenum__Site__r.Name;
         jobName = timesheet.sirenum__Team__r.Name;
         workerName = timesheet.sirenum__Worker__r.Name;
        
        // Query the shifts based on passed IDs
        shifts = [SELECT Id, sirenum__Contact__r.FirstName, sirenum__Contact__r.LastName,sirenum__Client_Approval_By__c,sirenum__Approved_By_Client__c,sirenum__Billable_Calculated_Shift_Length__c, 
                          sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c,sirenum__Site__r.Name,sirenum__Team__r.Name,sirenum__Shift_Date__c,sirenum__Client_Approval_By__r.Name
                   FROM sirenum__Shift__c 
                   WHERE Id IN :shiftIds order by sirenum__Scheduled_Start_Time__c DESC];

        
    }
}