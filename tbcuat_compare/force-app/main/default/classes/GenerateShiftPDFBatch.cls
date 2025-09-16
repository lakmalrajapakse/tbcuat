public class GenerateShiftPDFBatch implements Database.Batchable<SObject>, Database.Stateful {

    // The list of Timesheet IDs passed to the batch
    public List<Id> timesheetIds;

    public GenerateShiftPDFBatch(List<Id> timesheetIds) {
        this.timesheetIds = timesheetIds;
    }

    // Start method: Retrieve all shifts related to the Timesheet IDs
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query to get shifts related to the timesheetIds passed to the batch
        return Database.getQueryLocator([
            SELECT Id, sirenum__Timesheet_summaries__c
            FROM sirenum__Shift__c
            WHERE sirenum__Timesheet_summaries__c IN :timesheetIds 
            AND sirenum__Timesheet_summaries__r.ProofUploaded__c = false
        ]);
    }

    // Execute method: Process each batch of shifts and generate a PDF
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<sirenum__Shift__c> shifts = (List<sirenum__Shift__c>)scope;

        // Group shifts by Timesheet
        Map<Id, List<sirenum__Shift__c>> timesheetShiftsMap = new Map<Id, List<sirenum__Shift__c>>();

        for (sirenum__Shift__c shift : shifts) {
            if (!timesheetShiftsMap.containsKey(shift.sirenum__Timesheet_summaries__c)) {
                timesheetShiftsMap.put(shift.sirenum__Timesheet_summaries__c, new List<sirenum__Shift__c>());
            }
            timesheetShiftsMap.get(shift.sirenum__Timesheet_summaries__c).add(shift);
        }

        // For each Timesheet, generate a PDF with its related shifts
        for (Id timesheetId : timesheetShiftsMap.keySet()) {
            List<sirenum__Shift__c> shiftsForTimesheet = timesheetShiftsMap.get(timesheetId);
            ShiftPDFGenerator.generateAndAttachPdfForTimesheet(timesheetId, shiftsForTimesheet);
        }
    }

    // Finish method: After batch completes, you can do post-processing (e.g., sending a notification)
    public void finish(Database.BatchableContext bc) {
        // Post-processing (e.g., notify someone when the batch completes)
        System.debug('Batch processing completed.');
    }
}