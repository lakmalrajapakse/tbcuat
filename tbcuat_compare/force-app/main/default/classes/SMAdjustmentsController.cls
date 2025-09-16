public with sharing class SMAdjustmentsController {
    @AuraEnabled
    public static String getTimesheets(String requestJson) {
        GetTimesheetsRequest request = (GetTimesheetsRequest) JSON.deserialize(requestJson, GetTimesheetsRequest.class);
        GetTimesheetsResponse response = new GetTimesheetsResponse();
        response.Summaries = new List<TimesheetSummary>();

        TimesheetRetrievalService.GetTimesheetsRequest serviceRequest = new TimesheetRetrievalService.GetTimesheetsRequest();
        serviceRequest.weekStart = request.weekStart;
        serviceRequest.weekEnd = request.weekEnd;
        serviceRequest.filterBranches = request.filterBranches;
        serviceRequest.filterContacts = request.filterContacts;
        serviceRequest.filterRoles = request.filterRoles;
        serviceRequest.filterSites = request.filterSites;
        serviceRequest.filterTypes = new List<String>{ null, 'Normal', 'Adjustment' };
        serviceRequest.inTimeOnly = true;

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
            marshalledSummary.Type = summary.Type;
            marshalledSummary.PeriodDate = summary.PeriodDate;
            marshalledSummary.SiteName = summary.SiteName;
            marshalledSummary.TotalHours = summary.TotalHours;
            marshalledSummary.InTimeInvoiceNo = summary.InTimeInvoiceNo;

            response.Summaries.add(marshalledSummary);
        }

        return JSON.serialize(response);
    }

    @AuraEnabled
    public static Id adjust(String requestJson) {
        List<TimesheetAdjustmentService.AdjustmentRequest> requests = (List<TimesheetAdjustmentService.AdjustmentRequest>) JSON.deserialize(
            requestJson,
            List<TimesheetAdjustmentService.AdjustmentRequest>.class
        );
        return TimesheetAdjustmentService.adjustAsync(requests);
    }

    @AuraEnabled
    public static Id reverse(String requestJson) {
        List<TimesheetAdjustmentService.AdjustmentRequest> requests = (List<TimesheetAdjustmentService.AdjustmentRequest>) JSON.deserialize(
            requestJson,
            List<TimesheetAdjustmentService.AdjustmentRequest>.class
        );

        return TimesheetAdjustmentService.reverseAsync(requests);
    }

    public class GetTimesheetsRequest {
        public String weekStart { get; set; }
        public String weekEnd { get; set; }
        public List<String> filterContacts { get; set; }
        public List<String> filterSites { get; set; }
        public List<String> filterBranches { get; set; }
        public List<String> filterRoles { get; set; }
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
        public String Type { get; set; }
        public Date PeriodDate { get; set; }
        public String SiteName { get; set; }
        public Decimal TotalHours { get; set; }
        public String InTimeInvoiceNo { get; set; }
    }
}