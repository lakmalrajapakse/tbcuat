public with sharing class TimesheetGenerationService {
    public static void processPay(ProcessPayRequest request) {
        sirenum__Scheduled_Task__c task = getTimesheetGenerationTask();
        task.sirenum__Last_Error__c = null;
        task.sirenum__Configuration__c = getSerializedJsonConfig(request);
        task.sirenum__Executing__c = true;

        Database.update(task, AccessLevel.USER_MODE);

        task = getTimesheetGenerationTask();

        if (task.sirenum__Last_Error__c != null) {
            throw new ServiceException(task.sirenum__Last_Error__c);
        }
    }

    private static sirenum__Scheduled_Task__c getTimesheetGenerationTask() {
        List<sirenum__Scheduled_Task__c> matchingTasks = [
            SELECT Id, sirenum__Executing__c, sirenum__Last_Error__c, sirenum__Configuration__c
            FROM sirenum__Scheduled_Task__c
            WHERE sirenum__Task_Type__c = 'Timesheet Generation'
            WITH USER_MODE
        ];

        if (matchingTasks.size() < 1) {
            throw new ServiceException('No timesheet generation task found');
        }

        return matchingTasks.get(0);
    }

    private static String getSerializedJsonConfig(ProcessPayRequest request) {
        JsonConfig config = new JsonConfig();

        config.period.selectionClause =
            'sirenum__Start_Date__c >= ' +
            String.valueOf(request.startDate) +
            ' AND sirenum__Week_Ending__c <= ' +
            String.valueOf(request.endDate);

        config.period.orderByClause = 'sirenum__Week_Ending__c DESC';
        config.notify = UserInfo.getUserEmail();        

        if (request.filters.contactNames.size() > 0) {
            config.filter.put('Contact__c', new List<String>(request.filters.contactNames));
        }

        if (request.filters.siteNames.size() > 0) {
            config.filter.put('Site__c', new List<String>(request.filters.siteNames));
        }

        if (request.filters.roleNames.size() > 0) {
            config.filter.put('Team__c', new List<String>(request.filters.roleNames));
        }

        return JSON.serialize(config);
    }

    public class ProcessPayRequest {
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        public RequestFilters filters { get; set; }

        public ProcessPayRequest() {
            filters = new RequestFilters();
        }
    }

    public class RequestFilters {
        public List<String> contactNames { get; set; }
        public List<String> siteNames { get; set; }
        public List<String> roleNames { get; set; }

        public RequestFilters() {
            contactNames = new List<String>();
            siteNames = new List<String>();
            roleNames = new List<String>();
        }
    }

    public class ServiceException extends Exception {
    }

    private class JsonConfig {
        public JsonConfigPeriod period { get; set; }
        public String notify { get; set; }
        public Map<String, List<String>> filter { get; set; }

        public JsonConfig() {
            period = new JsonConfigPeriod();
            filter = new Map<String, List<String>>();
        }
    }

    private class JsonConfigPeriod {
        public String selectionClause { get; set; }
        public String orderByClause { get; set; }

        public JsonConfigPeriod() {
            selectionClause = '';
            orderByClause = '';
        }
    }
}