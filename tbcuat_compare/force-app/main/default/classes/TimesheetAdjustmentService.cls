public with sharing class TimesheetAdjustmentService {
    public static Id adjustAsync(List<AdjustmentRequest> requests) {
        return Database.executeBatch(new TimesheetAdjustmentBatch(requests), 2);
    }

    public static void adjust(AdjustmentRequest request) {
        adjust(new List<AdjustmentRequest>{ request });
    }

    public static void adjust(List<AdjustmentRequest> requests) {
        Map<Id, AdjustmentContext> adjustmentContextsByTimesheetId = new Map<Id, AdjustmentContext>();
        
        for (AdjustmentRequest request: requests) {
            if (request.timesheet == null) {
                return;
            }
        }

        populateContextsWithRequests(adjustmentContextsByTimesheetId, requests);
        populateContextsWithSourceTimesheetsAndLines(adjustmentContextsByTimesheetId);
        populateContextsWithAdjustedTimesheets(adjustmentContextsByTimesheetId);
        populateContextsWithReversalTimesheets(adjustmentContextsByTimesheetId);
        populateContextsWithAdjustedTimesheetLines(adjustmentContextsByTimesheetId);
        populateContextsWithReversalTimesheetLines(adjustmentContextsByTimesheetId);
        populateContextsWithAdjustmentRecords(adjustmentContextsByTimesheetId);
        populateContextsWithUpdatedShifts(adjustmentContextsByTimesheetId);
        insertAndUpdateRecords(adjustmentContextsByTimesheetId);
    }

    public static void reverse(List<AdjustmentRequest> requests) {
        Map<Id, AdjustmentContext> adjustmentContextsByTimesheetId = new Map<Id, AdjustmentContext>();

        for (AdjustmentRequest request : requests) {
            request.reversalOnly = true;
        }

        adjust(requests);
    }

    public static Id reverseAsync(List<AdjustmentRequest> requests) {
        return Database.executeBatch(new TimesheetAdjustmentReversalBatch(requests), 2);
    }

    private static List<sirenum__Timesheet__c> getTimesheetsWithLines(Set<Id> recordIds) {
        List<Sirenum__Timesheet__c> timesheets = [
            SELECT
                Id,
                Timesheet_Type__c,
                sirenum__Worker__c,
                sirenum__Worked_Period__c,
                sirenum__Week_Ending__c,
                sirenum__Week__c,
                sirenum__TimesheetType__c,
                sirenum__Team__c,
                sirenum__Taxed_Expenses__c,
                sirenum__Taxed_Deductions__c,
                sirenum__Site__c,
                sirenum__Signatures__c,
                sirenum__Sage_Description__c,
                sirenum__Rate_Description__c,
                sirenum__PO_Number__c,
                sirenum__PO_Expires__c,
                sirenum__Payroll_Comments__c,
                sirenum__Pay_Advice_Comments__c,
                sirenum__Non_Taxed_Expenses__c,
                sirenum__Non_Taxed_Deductions__c,
                sirenum__Lock__c,
                sirenum__Loan_Repayment__c,
                sirenum__Limited_Company_Comment__c,
                sirenum__Invoice_Job_ID__c,
                sirenum__Invoice_Comment__c,
                sirenum__Invoice__c,
                sirenum__Incurred_cost__c,
                sirenum__Holiday_Payout__c,
                sirenum__HaveTimeSheet__c,
                sirenum__Have_Signed_Timesheet__c,
                sirenum__Contract__c,
                sirenum__Cloned_From__c,
                sirenum__Client__c,
                sirenum__Charge_Description__c,
                sirenum__Charge_Bonus_to_Client__c,
                sirenum__Bonus__c,
                sirenum__Assignment__c,
                Plan_Code__c,
                Placement__c,
                LastIntimeSync__c,
                (
                    SELECT Id, sirenum__Timesheet_summaries__c
                    FROM sirenum__Shifts__r
                ),
                (
                    SELECT
                        Id,
                        sirenum__Travel_time__c,
                        sirenum__Total_Pay__c,
                        sirenum__Total_Charge__c,
                        sirenum__Standard_Rate__c,
                        sirenum__Shift__c,
                        sirenum__RateType__c,
                        sirenum__Rate_Modifier__c,
                        sirenum__Rate_Line__c,
                        sirenum__Rate__c,
                        sirenum__Payment_reference_number__c,
                        sirenum__Overtime_Rate__c,
                        sirenum__Origin__c,
                        sirenum__Line_Type__c,
                        sirenum__Is_Locked__c,
                        sirenum__Is_Break_Deduction__c,
                        sirenum__Invalid_shift_rates__c,
                        sirenum__Hours__c,
                        sirenum__Holiday_Rate__c,
                        sirenum__Exact_Rate_Time__c,
                        sirenum__Description__c,
                        sirenum__Day_Number__c,
                        sirenum__Date__c,
                        sirenum__Cost_Matrix__c,
                        sirenum__Contact_ID__c,
                        sirenum__Code__c,
                        sirenum__Charge__c,
                        ShiftStartTimeUnixEpoch__c,
                        ShiftEndTimeUnixEpoch__c,
                        HoursInMilliseconds__c,
                        DateUnixEpoch__c,
                        IntimePayElement__c
                    FROM sirenum__Timesheet_Lines__r
                )
            FROM sirenum__Timesheet__c
            WHERE Id IN :recordIds
            WITH SYSTEM_MODE
        ];

        return timesheets;
    }

    private static void populateContextsWithRequests(
        Map<Id, AdjustmentContext> contextsByTimesheetId,
        List<AdjustmentRequest> requests
    ) {
        for (AdjustmentRequest request : requests) {
            AdjustmentContext context = new AdjustmentContext();
            context.request = request;

            if (context.request.reversalOnly == null) {
                context.request.reversalOnly = false;
            }

            if (context.request.timesheet.lines == null) {
                context.request.timesheet.lines = new List<AdjustmentTimesheetLine>();
            }

            contextsByTimesheetId.put(request.timesheet.timesheetId, context);
        }
    }

    private static void populateContextsWithSourceTimesheetsAndLines(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        Map<Id, sirenum__Timesheet__c> timesheetsById = new Map<Id, sirenum__Timesheet__c>(
            getTimesheetsWithLines(timesheetIds)
        );

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            context.originalTimesheet = timesheetsById.get(timesheetId);
            context.originalTimesheetLinesByOriginalId = new Map<Id, sirenum__Timesheet_Line__c>(
                context.originalTimesheet.sirenum__Timesheet_Lines__r
            );
        }
    }

    private static void populateContextsWithAdjustedTimesheets(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            context.originalTimesheet.Timesheet_Type__c = 'Adjusted';

            if (context.request.reversalOnly == true) {
                continue;
            }

            context.adjustedTimesheet = context.originalTimesheet.clone();
            context.adjustedTimesheet.Timesheet_Type__c = 'Adjustment';
            context.adjustedTimesheet.Original_Timesheet__c = context.originalTimesheet.Id;

            if (context.request.timesheet.poNumber != null) {
                context.adjustedTimesheet.sirenum__PO_Number__c = context.request.timesheet.poNumber;
                context.adjustedTimesheet.Timesheet_Type__c = 'Adjustment';
            }
        }
    }

    private static void populateContextsWithReversalTimesheets(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            context.reversalTimesheet = context.originalTimesheet.clone();
            context.reversalTimesheet.Timesheet_Type__c = 'Reversal';
        }
    }

    private static void populateContextsWithAdjustedTimesheetLines(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            if (context.request.reversalOnly == true) {
                continue;
            }

            context.adjustedTimesheetLinesByOriginalId = new Map<Id, sirenum__Timesheet_Line__c>();

            Map<Id, AdjustmentTimesheetLine> adjustmentLinesByOriginalId = new Map<Id, AdjustmentTimesheetLine>();

            for (AdjustmentTimesheetLine adjustmentLine : context.request.timesheet.lines) {
                adjustmentLinesByOriginalId.put(adjustmentLine.timesheetLineId, adjustmentLine);
            }

            for (Id originalTimesheetLineId : context.originalTimesheetLinesByOriginalId.keySet()) {
                sirenum__Timesheet_Line__c originalLine = context.originalTimesheetLinesByOriginalId.get(
                    originalTimesheetLineId
                );
                sirenum__Timesheet_Line__c adjustedLine = originalLine.clone();
                adjustedLine.Timesheet_Type__c = 'Adjustment';

                AdjustmentTimesheetLine adjustment = adjustmentLinesByOriginalId.get(originalTimesheetLineId);

                if (adjustment != null && adjustment.chargeRate != null) {
                    adjustedLine.sirenum__Charge__c = adjustment.chargeRate;
                }

                if (adjustment != null && adjustment.payRate != null) {
                    adjustedLine.sirenum__Rate__c = adjustment.payRate;
                }

                if (adjustment != null && adjustment.inTimePayElement != null) {
                    adjustedLine.IntimePayElement__c = adjustment.inTimePayElement;
                }

                context.adjustedTimesheetLinesByOriginalId.put(originalLine.Id, adjustedLine);
            }
        }
    }

    private static void populateContextsWithReversalTimesheetLines(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();
        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            for (Id originalTimesheetLineId : context.originalTimesheetLinesByOriginalId.keySet()) {
                sirenum__Timesheet_Line__c originalLine = context.originalTimesheetLinesByOriginalId.get(
                    originalTimesheetLineId
                );

                sirenum__Timesheet_Line__c reversalLine = originalLine.clone();
                reversalLine.Timesheet_Type__c = 'Reversal';
                reversalLine.sirenum__Hours__c = -reversalLine.sirenum__Hours__c;
                context.reversalTimesheetLinesByOriginalId.put(originalLine.Id, reversalLine);
            }
        }
    }

    private static void populateContextsWithAdjustmentRecords(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            context.adjustment = new Timesheet_Adjustment__c(Type__c = 'Adjustment');

            Boolean adjustingPay = false;
            Boolean adjustingCharge = false;

            for (TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine : context.request.timesheet.lines) {
                if (adjustmentLine.chargeRate != null) {
                    adjustingCharge = true;
                }

                if (adjustmentLine.payRate != null) {
                    adjustingPay = true;
                }
            }

            if (adjustingPay) {
                if (adjustingCharge) {
                    context.adjustment = new Timesheet_Adjustment__c(Type__c = 'Adjustment');
                } else {
                    context.adjustment = new Timesheet_Adjustment__c(Type__c = 'Adjustment Pay Only');
                }
            } else if (adjustingCharge) {
                context.adjustment = new Timesheet_Adjustment__c(Type__c = 'Adjustment Charge Only');
            }
        }
    }

    private static void populateContextsWithUpdatedShifts(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            for (sirenum__Shift__c shift : context.originalTimesheet.sirenum__Shifts__r) {
                sirenum__Shift__c updatedShift = new sirenum__Shift__c(Id = shift.Id);
                updatedShift.Original_Timesheet__c = context.originalTimesheet.Id;
                context.updatedShifts.add(updatedShift);
            }
        }
    }

    private static void insertAndUpdateRecords(Map<Id, AdjustmentContext> contextsByTimesheetId) {
        List<SObject> recordsToInsert = new List<SObject>();
        List<SObject> recordsToUpdate = new List<SObject>();
        Set<Id> timesheetIds = contextsByTimesheetId.keySet();

        // Insert adjustments
        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            recordsToInsert.add(context.adjustment);
        }

        Database.insert(recordsToInsert, AccessLevel.SYSTEM_MODE);
        recordsToInsert.clear();

        // Insert the new adjusted timesheets
        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            if (context.adjustedTimesheet != null) {
                context.adjustedTimesheet.Adjustment__c = context.adjustment.Id;
                recordsToInsert.add(context.adjustedTimesheet);
            }

            context.reversalTimesheet.Adjustment__c = context.adjustment.Id;
            recordsToInsert.add(context.reversalTimesheet);
        }

        Database.insert(recordsToInsert, AccessLevel.SYSTEM_MODE);
        recordsToInsert.clear();

        // Set the timesheet ids on the new lines, and insert them.
        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);

            for (sirenum__Timesheet_Line__c adjustedLine : context.adjustedTimesheetLinesByOriginalId.values()) {
                adjustedLine.sirenum__Timesheet__c = context.adjustedTimesheet.Id;
                recordsToInsert.add(adjustedLine);
            }

            for (sirenum__Timesheet_Line__c reversalLine : context.reversalTimesheetLinesByOriginalId.values()) {
                reversalLine.sirenum__Timesheet__c = context.reversalTimesheet.Id;
                recordsToInsert.add(reversalLine);
            }

            for (sirenum__Shift__c shift : context.updatedShifts) {
                if (context.request.reversalOnly) {
                    shift.sirenum__Timesheet_summaries__c = null;
                }

                shift.Timesheet_Adjustment__c = context.adjustment.Id;
                recordsToUpdate.add(shift);
            }
        }

        Database.insert(recordsToInsert, AccessLevel.SYSTEM_MODE);
        recordsToInsert.clear();

        // Update the original timesheets
        for (Id timesheetId : timesheetIds) {
            AdjustmentContext context = contextsByTimesheetId.get(timesheetId);
            context.originalTimesheet.Adjustment__c = context.adjustment.Id;
            recordsToUpdate.add(context.originalTimesheet);
        }

        Database.update(recordsToUpdate, AccessLevel.SYSTEM_MODE);
        recordsToUpdate.clear();
    }

    public class AdjustmentRequest {
        public AdjustmentTimesheet timesheet { get; set; }
        public Boolean reversalOnly { get; set; }
    }

    public class AdjustmentTimesheet {
        public Id timesheetId { get; set; }
        public String poNumber { get; set; }
        public List<AdjustmentTimesheetLine> lines { get; set; }
    }

    public class AdjustmentTimesheetLine {
        public Id timesheetLineId { get; set; }
        public Decimal chargeRate { get; set; }
        public Decimal payRate { get; set; }
        public String inTimePayElement { get; set; }
    }

    private class AdjustmentContext {
        public AdjustmentRequest request { get; set; }
        public sirenum__Timesheet__c originalTimesheet { get; set; }
        public sirenum__Timesheet__c adjustedTimesheet { get; set; }
        public sirenum__Timesheet__c reversalTimesheet { get; set; }
        public Timesheet_Adjustment__c adjustment { get; set; }

        public Map<Id, sirenum__Timesheet_Line__c> originalTimesheetLinesByOriginalId { get; set; }
        public Map<Id, sirenum__Timesheet_Line__c> reversalTimesheetLinesByOriginalId { get; set; }
        public Map<Id, sirenum__Timesheet_Line__c> adjustedTimesheetLinesByOriginalId { get; set; }
        public List<sirenum__Shift__c> updatedShifts { get; set; }

        public AdjustmentContext() {
            originalTimesheetLinesByOriginalId = new Map<Id, sirenum__Timesheet_Line__c>();
            reversalTimesheetLinesByOriginalId = new Map<Id, sirenum__Timesheet_Line__c>();
            adjustedTimesheetLinesByOriginalId = new Map<Id, sirenum__Timesheet_Line__c>();
            updatedShifts = new List<sirenum__Shift__c>();
        }
    }
}