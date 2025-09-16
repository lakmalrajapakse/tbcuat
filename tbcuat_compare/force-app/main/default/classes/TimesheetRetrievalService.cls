public with sharing class TimesheetRetrievalService {
    private static final List<String> FIELDS_TO_SELECT = new List<String>{
        'Id',
        'Name',
        'sirenum__Total_Pay__c',
        'sirenum__Total_Charge__c',
        'sirenum__Shift__c',
        'sirenum__Hours__c',
        'sirenum__Charge__c',
        'sirenum__Rate__c',
        'sirenum__Date__c',
        'IntimePayElement__c',
        'sirenum__Timesheet__c',
        'sirenum__Timesheet__r.Name',
        'sirenum__Timesheet__r.Timesheet_Type__c',
        'sirenum__Timesheet__r.InTime_Invoice_No__c',
        'sirenum__Timesheet__r.sirenum__Total_Hours__c',
        'sirenum__Timesheet__r.sirenum__Total_Pay__c',
        'sirenum__Timesheet__r.sirenum__Total_Charge__c',
        'sirenum__Timesheet__r.sirenum__PO_Number__c',
        'sirenum__Timesheet__r.sirenum__Worker__r.Name',
        'sirenum__Timesheet__r.sirenum__Team__r.Name',
        'sirenum__Timesheet__r.sirenum__Site__r.Name',
        'sirenum__Timesheet__r.sirenum__Week_Ending__c',
        'sirenum__Timesheet__r.sirenum__Worker__r.InTimeExternalId__c',
        'sirenum__Timesheet__r.sirenum__Worked_Period__r.sirenum__Week_Ending__c'
    };

    public static GetTimesheetsResponse getFilteredTimesheets(GetTimesheetsRequest request) {
        String soql = 'SELECT ' + String.join(FIELDS_TO_SELECT, ', ') + ' FROM sirenum__Timesheet_Line__c ';

        Date startDate;
        Date endDate;
        List<String> filterContacts = request.filterContacts;
        List<String> filterSites = request.filterSites;
        List<String> filterRoles = request.filterRoles;
        List<String> filterTypes = request.filterTypes;
        List<String> filterPlans = request.filterPlanCodes;
        Set<Id> filterTimesheetIds = request.timesheetIds;
        String filterInvoiceNo = request.inTimeInvoiceNo;
        List<String> whereClauses = new List<String>();

        if (request.weekStart != null) {
            List<String> splitStartDate = request.weekStart.split('/');

            startDate = Date.newInstance(
                Integer.valueOf(splitStartDate[2]),
                Integer.valueOf(splitStartDate[0]),
                Integer.valueOf(splitStartDate[1])
            );

            whereClauses.add('sirenum__Timesheet__r.sirenum__Week__r.sirenum__Start_Date__c >= :startDate');
        }

        if (request.weekEnd != null) {
            List<String> splitEndDate = request.weekEnd.split('/');

            endDate = Date.newInstance(
                Integer.valueOf(splitEndDate[2]),
                Integer.valueOf(splitEndDate[0]),
                Integer.valueOf(splitEndDate[1])
            );

            whereClauses.add('sirenum__Timesheet__r.sirenum__Week__r.sirenum__Start_Date__c <= :endDate');
        }

        if (filterContacts != null && !filterContacts.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__r.sirenum__Worker__c IN:filterContacts');
        }

        if (filterSites != null && !filterSites.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__r.sirenum__Site__c IN:filterSites');
        }

        if (filterPlans != null && !filterPlans.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__r.sirenum__Worker__r.Plan_Code__c IN:filterPlans');
        }

        if (filterRoles != null && !filterRoles.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__r.sirenum__Team__c IN:filterRoles');
        }

        if (filterTypes != null && !filterTypes.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__r.Timesheet_Type__c IN:filterTypes');
        }

        if (request.inTimeOnly == true) {
            whereClauses.add('sirenum__Timesheet__r.InTimeId__c != NULL');
        }

        if (filterTimesheetIds != null && !filterTimesheetIds.isEmpty()) {
            whereClauses.add('sirenum__Timesheet__c IN :filterTimesheetIds');
        }

        if (filterInvoiceNo != null) {
            whereClauses.add('sirenum__Timesheet__r.InTime_Invoice_No__c = :filterInvoiceNo');
        }

        if (whereClauses.size() > 0) {
            soql += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        List<sirenum__Timesheet_Line__c> timesheetLines = Database.query(soql);
        return createResponseFromTimesheetLines(timesheetLines);
    }

    public static GetTimesheetsResponse getTimesheetsById(Set<Id> timesheetIds) {
        String soql =
            'SELECT ' +
            String.join(FIELDS_TO_SELECT, ', ') +
            ' FROM sirenum__Timesheet_Line__c WHERE sirenum__Timesheet__c IN :timesheetIds';

        List<sirenum__Timesheet_Line__c> timesheetLines = Database.query(soql);
        return createResponseFromTimesheetLines(timesheetLines);
    }

    private static GetTimesheetsResponse createResponseFromTimesheetLines(
        List<sirenum__Timesheet_Line__c> timesheetLines
    ) {
        GetTimesheetsResponse response = new GetTimesheetsResponse();
        response.Summaries = new List<TimesheetSummary>();

        Map<Id, TimesheetSummary> summariesById = new Map<Id, TimesheetSummary>();

        for (sirenum__Timesheet_Line__c timesheetLine : timesheetLines) {
            TimesheetSummary summary = summariesById.get(timesheetLine.sirenum__Timesheet__c);

            if (summary == null) {
                summary = new TimesheetSummary();
                summary.Id = timesheetLine.sirenum__Timesheet__c;
                summary.Name = timesheetLine.sirenum__Timesheet__r.Name;
                summary.Pay = timesheetLine.sirenum__Timesheet__r.sirenum__Total_Pay__c;
                summary.Charge = timesheetLine.sirenum__Timesheet__r.sirenum__Total_Charge__c;
                summary.WorkerName = timesheetLine.sirenum__Timesheet__r.sirenum__Worker__r.Name;
                summary.PONumber = timesheetLine.sirenum__Timesheet__r.sirenum__PO_Number__c;
                summary.JobRole = timesheetLine.sirenum__Timesheet__r.sirenum__Team__r.Name;
                summary.Type = timesheetLine.sirenum__Timesheet__r.Timesheet_Type__c != null
                    ? timesheetLine.sirenum__Timesheet__r.Timesheet_Type__c
                    : 'Normal';
                summary.PeriodDate = timesheetLine.sirenum__Timesheet__r.sirenum__Worked_Period__r.sirenum__Week_Ending__c;
                summary.SiteName = timesheetLine.sirenum__Timesheet__r.sirenum__Site__r.Name;
                summary.TotalHours = timesheetLine.sirenum__Timesheet__r.sirenum__Total_Hours__c;
                summary.InTimeInvoiceNo = timesheetLine.sirenum__Timesheet__r.InTime_Invoice_No__c;
                summary.TotalHours = timesheetLine.sirenum__Timesheet__r.sirenum__Total_Hours__c;
                summary.WeekEndingDate = timesheetLine.sirenum__Timesheet__r?.sirenum__Week_Ending__c;
                summary.InTimeExternalId = timesheetLine.sirenum__Timesheet__r.sirenum__Worker__r.InTimeExternalId__c;
                summary.Lines = new List<TimesheetLine>();
                summariesById.put(timesheetLine.sirenum__Timesheet__c, summary);
                response.Summaries.add(summary);
            }

            TimesheetLine line = new TimesheetLine();
            line.Id = timesheetLine.Id;
            line.Name = timesheetLine.Name;
            line.Pay = timesheetLine.sirenum__Total_Pay__c;
            line.Charge = timesheetLine.sirenum__Total_Charge__c;
            line.ShiftId = timesheetLine.sirenum__Shift__c;
            line.SummaryId = timesheetLine.sirenum__Timesheet__c;
            line.TotalHours = timesheetLine.sirenum__Hours__c;
            line.ChargeRate = timesheetLine.sirenum__Charge__c;
            line.PayRate = timesheetLine.sirenum__Rate__c;
            line.TotalHours = timesheetLine.sirenum__Hours__c;
            line.WeekEndingDate = timesheetLine.sirenum__Date__c;
            line.InTimePayElement = timesheetLine.IntimePayElement__c;

            summary.Lines.add(line);
        }

        return response;
    }

    public class GetTimesheetsRequest {
        public String weekStart { get; set; }
        public String weekEnd { get; set; }
        public List<String> filterContacts { get; set; }
        public List<String> filterSites { get; set; }
        public List<String> filterBranches { get; set; }
        public List<String> filterRoles { get; set; }
        public List<String> filterTypes { get; set; }
        public List<String> filterPlanCodes { get; set; }
        public Set<Id> timesheetIds { get; set; }
        public String inTimeInvoiceNo { get; set; }
        public Boolean inTimeOnly { get; set; }
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
        public String SiteName { get; set; }
        public String Type { get; set; }
        public Decimal TotalHours { get; set; }
        public Date PeriodDate { get; set; }
        public String InTimeInvoiceNo { get; set; }
        public Date WeekEndingDate { get; set; }
        public String InTimeExternalId { get; set; }
        public List<TimesheetLine> Lines { get; set; }
    }

    public class TimesheetLine {
        public Id Id { get; set; }
        public Id SummaryId { get; set; }
        public Id ShiftId { get; set; }
        public String Name { get; set; }
        public Decimal Pay { get; set; }
        public Decimal Charge { get; set; }
        public Decimal PayRate { get; set; }
        public Decimal ChargeRate { get; set; }
        public Decimal TotalHours { get; set; }
        public Date WeekEndingDate { get; set; }
        public String InTimePayElement { get; set; }
    }
}