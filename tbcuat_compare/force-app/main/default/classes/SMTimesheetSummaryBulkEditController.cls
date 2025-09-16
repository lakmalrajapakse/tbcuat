public with sharing class SMTimesheetSummaryBulkEditController {
    @AuraEnabled
    public static void updateTimesheets(String timesheetsBulkEditJson) {
        try {
            TimesheetSummaryBulkEditDto timesheetsBulkEdit = (TimesheetSummaryBulkEditDto) JSON.deserialize(
                timesheetsBulkEditJson,
                TimesheetSummaryBulkEditDto.class
            );

            List<sirenum__Timesheet__c> timesheetsToUpdate = new List<sirenum__Timesheet__c>();

            for (Id timesheetId : timesheetsBulkEdit.recordIds) {
                timesheetsToUpdate.add(
                    new sirenum__Timesheet__c(Id = timesheetId, sirenum__PO_Number__c = timesheetsBulkEdit.poNumber)
                );
            }

            Boolean allOrNone = true;

            Database.update(timesheetsToUpdate, allOrNone, AccessLevel.USER_MODE);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'SMTimesheetSummaryBulkEditController | ErrorCode: 01 | ' + e.getMessage()
            );

            throw new AuraHandledException('Error occurred during Timesheet Update: ' + e.getMessage());
        }
    }

    public class TimesheetSummaryBulkEditDto {
        public List<Id> recordIds { get; set; }
        public String poNumber { get; set; }
    }
}