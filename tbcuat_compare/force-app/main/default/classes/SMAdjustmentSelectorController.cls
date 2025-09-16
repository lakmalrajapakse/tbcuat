public with sharing class SMAdjustmentSelectorController {
    static final List<Schema.PicklistEntry> PAY_ELEMENT_ENTRIES = sirenum__Timesheet_Line__c.IntimePayElement__c.getDescribe()
        .getPicklistValues();

    @AuraEnabled
    public static List<PicklistOption> getPayElementOptions() {
        List<PicklistOption> results = new List<PicklistOption>();
        for (Schema.PicklistEntry entry : PAY_ELEMENT_ENTRIES) {
            if (!entry.isActive()) {
                continue;
            }

            PicklistOption option = new PicklistOption();
            option.label = entry.getLabel();
            option.value = entry.getValue();

            results.add(option);
        }

        return results;
    }

    @AuraEnabled
    public static String getTimesheets(String requestJson) {
        GetTimesheetsRequest request = (GetTimesheetsRequest) JSON.deserialize(requestJson, GetTimesheetsRequest.class);
        GetTimesheetsResponse response = new GetTimesheetsResponse();
        response.Summaries = new List<TimesheetSummary>();

        TimesheetRetrievalService.GetTimesheetsRequest serviceRequest = new TimesheetRetrievalService.GetTimesheetsRequest();

        if (request.invoiceNo != null) {
            serviceRequest.inTimeInvoiceNo = request.invoiceNo;
        } else {
            serviceRequest.timesheetIds = new Set<Id>(request.timesheetIds);
        }

        TimesheetRetrievalService.GetTimesheetsResponse serviceResponse = TimesheetRetrievalService.getFilteredTimesheets(
            serviceRequest
        );

        response.Summaries = new List<TimesheetSummary>();

        for (TimesheetRetrievalService.TimesheetSummary summary : serviceResponse.Summaries) {
            TimesheetSummary marshalledSummary = new TimesheetSummary();
            marshalledSummary.Id = summary.Id;
            marshalledSummary.Name = summary.Name;
            marshalledSummary.Pay = summary.Pay;
            marshalledSummary.Charge = summary.Charge;
            marshalledSummary.WorkerName = summary.WorkerName;
            marshalledSummary.PONumber = summary.PONumber;
            marshalledSummary.JobRole = summary.JobRole;
            marshalledSummary.TotalHours = summary.TotalHours;
            marshalledSummary.Lines = new List<TimesheetLine>();

            for (TimesheetRetrievalService.TimesheetLine line : summary.Lines) {
                TimesheetLine marshalledLine = new TimesheetLine();

                marshalledLine.Id = line.Id;
                marshalledLine.SummaryId = line.SummaryId;
                marshalledLine.ShiftId = line.ShiftId;
                marshalledLine.ShiftId = line.ShiftId;
                marshalledLine.Name = line.Name;
                marshalledLine.Pay = line.Pay;
                marshalledLine.Charge = line.Charge;
                marshalledLine.PayRate = line.PayRate;
                marshalledLine.ChargeRate = line.ChargeRate;
                marshalledLine.TotalHours = line.TotalHours;
                marshalledLine.InTimePayElement = line.InTimePayElement;

                marshalledSummary.Lines.add(marshalledLine);
            }

            response.Summaries.add(marshalledSummary);
        }

        return JSON.serialize(response);
    }

    public class PicklistOption {
        @AuraEnabled
        public string label { get; set; }
        @AuraEnabled
        public String value { get; set; }
    }

    public class GetTimesheetsRequest {
        public List<Id> timesheetIds { get; set; }
        public String invoiceNo { get; set; }
    }

    public class GetTimesheetsResponse {
        public List<TimesheetSummary> Summaries { get; set; }
    }

    public class TimesheetSummary {
        public Id Id { get; set; }
        public String Name { get; set; }
        public Decimal Pay { get; set; }
        public Decimal Charge { get; set; }
        public String WorkerName { get; set; }
        public String PONumber { get; set; }
        public String JobRole { get; set; }
        public Decimal TotalHours { get; set; }
        public List<TimesheetLine> Lines { get; set; }
    }

    public class TimesheetLine {
        public Id Id { get; set; }
        public Id SummaryId { get; set; }
        public Id ShiftId { get; set; }
        public String Name { get; set; }
        public Decimal Pay { get; set; }
        public Decimal Charge { get; set; }
        public Decimal TotalHours { get; set; }
        public Decimal PayRate { get; set; }
        public Decimal ChargeRate { get; set; }
        public String InTimePayElement { get; set; }
    }
}