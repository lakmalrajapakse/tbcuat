public with sharing class SMTimesheetsController {
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
        serviceRequest.filterPlanCodes = request.filterPlanCodes;

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
            marshalledSummary.WeekEndingDate = summary.PeriodDate;
            marshalledSummary.InTimeExternalId = summary.InTimeExternalId;
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
                marshalledLine.TotalHours = line.TotalHours;
                marshalledLine.WeekEndingDate = line.WeekEndingDate;

                marshalledSummary.Lines.add(marshalledLine);
            }

            response.Summaries.add(marshalledSummary);
        }

        return JSON.serialize(response);
    }

    public class GetTimesheetsRequest {
        public String weekStart { get; set; }
        public String weekEnd { get; set; }
        public List<String> filterContacts { get; set; }
        public List<String> filterSites { get; set; }
        public List<String> filterBranches { get; set; }
        public List<String> filterRoles { get; set; }
        public List<String> filterPlanCodes { get; set; }
    }

    public class GetTimesheetsResponse {
        public List<TimesheetSummary> Summaries { get; set; }
    }

    public class TimesheetSummary {
        public Id Id { get; set; }
        public String Name { get; set; }
        public Decimal Pay { get; set; }
        public Decimal Charge { get; set; }
        public Decimal TotalHours { get; set; }
        public Date WeekEndingDate { get; set; }
        public String WorkerName { get; set; }
        public String PONumber { get; set; }
        public String JobRole { get; set; }
        public String InTimeExternalId { get; set; }
        public List<TimesheetLine> Lines { get; set; }
    }

    public class TimesheetLine {
        public Id Id { get; set; }
        public Id SummaryId { get; set; }
        public Id ShiftId { get; set; }
        public String Name { get; set; }
        public Decimal Pay { get; set; }
        public Decimal TotalHours { get; set; }
        public Date WeekEndingDate { get; set; }
        public Decimal Charge { get; set; }
    }
}