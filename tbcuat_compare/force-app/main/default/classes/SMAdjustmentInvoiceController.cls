public with sharing class SMAdjustmentInvoiceController {
    @AuraEnabled
    public static String getInvoiceEntries(String requestJson) {
        GetInvoiceEntriesRequest request = (GetInvoiceEntriesRequest) JSON.deserialize(
            requestJson,
            GetInvoiceEntriesRequest.class
        );
        GetInvoiceEntriesResponse response = new GetInvoiceEntriesResponse();
        response.invoiceEntries = new List<String>();

        TimesheetRetrievalService.GetTimesheetsResponse serviceResponse = TimesheetRetrievalService.getTimesheetsById(
            new Set<Id>(request.TimesheetIds)
        );

        for (TimesheetRetrievalService.TimesheetSummary summary : serviceResponse.Summaries) {
            response.invoiceEntries.add(summary.InTimeInvoiceNo);
        }

        return JSON.serialize(response);
    }

    public class GetInvoiceEntriesRequest {
        public List<Id> timesheetIds { get; set; }
    }

    public class GetInvoiceEntriesResponse {
        public List<String> invoiceEntries { get; set; }
    }
}