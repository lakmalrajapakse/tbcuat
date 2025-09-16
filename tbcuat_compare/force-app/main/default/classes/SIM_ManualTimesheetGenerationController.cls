public with sharing class SIM_ManualTimesheetGenerationController {
    private final static Integer MAX_RESULTS = 5;

    @AuraEnabled
    public static String getBatchProgress(String batchId) {
        StatusInfo statusInfo = getStatusInfo(batchId);
        if (statusInfo == null) {
            return JSON.serialize(new SIM_Response.ErrorResponse('Error getting status.'));
        } else {
            return JSON.serialize(new SIM_Response.SuccessResponse(statusInfo));
        }
    }


    @AuraEnabled(Cacheable=true)
    public static String getUploadTemplates() {
        List<SIM_Option> templates = new List<SIM_Option>();
        for (Manual_Timesheet_Generation_Templates__mdt template : [select DeveloperName, MasterLabel from Manual_Timesheet_Generation_Templates__mdt order by MasterLabel]) {
            templates.add(new SIM_Option(template.DeveloperName, template.MasterLabel));
        }        
        
        return JSON.serialize(templates);
    } 

    @AuraEnabled
    public static String loadData(String template, String filename, Integer hrow, Integer drow, String payrollPeriod, String jsonString) {        
        String batchProcessId;
        try {
            System.debug(filename + ' : ' + template + ' : ' + hrow + ' : ' + drow + ' : ' + jsonString);
            
            SIM_ManualTimesheetGeneration uploader = new SIM_ManualTimesheetGeneration(filename, template, payrollPeriod, hrow, drow);
            batchProcessId = uploader.submitBatch(jsonString);
        } catch (Exception e){
            return JSON.serialize(new SIM_Response.ErrorResponse('Error: ' + e.getMessage() + ' - ' + e.getLineNumber()));            
        }
        
        return JSON.serialize(new SIM_Response.SuccessResponse(batchProcessId));
    }

    @AuraEnabled(Cacheable=true)
    public static List<SIM_LookupSearchResult> searchPeriods(String searchTerm, List<String> selectedIds) {
        // Prepare query paramters
        searchTerm += '*';

        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                sirenum__Week__c(Id, Name, sirenum__Start_Date__c WHERE sirenum__PayrollCycle__c in :selectedIds)               
            LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String periodIcon = 'standard:default';
        sirenum__Week__c[] periods = (List<sirenum__Week__c>) searchResults[0];
        for (sirenum__Week__c period : periods) {
            results.add(
                new SIM_LookupSearchResult(
                    period.Id,
                    'sirenum__Week__c',
                    periodIcon,
                    period.Name,
                    'Period • ' + period.sirenum__Start_Date__c
                )
            );
        }
        
        // Optionally sort all results on title
        results.sort();

        return results;
    }


    @AuraEnabled(Cacheable=true)
    public static List<SIM_LookupSearchResult> searchPayCycles(String searchTerm, List<String> selectedIds) {
        // Prepare query paramters
        searchTerm = '%' +  searchTerm + '%';

        // Prepare results
        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();
        
        String pcycleIcon = 'standard:default';
                
        for (sirenum__Payroll_Cycle__c pcycle : [select id, name from sirenum__Payroll_Cycle__c where name like :searchTerm limit :MAX_RESULTS]) {
            results.add(
                new SIM_LookupSearchResult(
                    pcycle.Id,
                    'sirenum__Payroll_Cycle__c',
                    pcycleIcon,
                    pcycle.Name,
                    'Pay Cycle • ' + pcycle.Name
                )
            );
        }
        
        // Optionnaly sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled(Cacheable=true)
    public static List<SIM_LookupSearchResult> getRecentlyViewedPayCycles() {
        return getRecentlyViewed('sirenum__Payroll_Cycle__c', 'standard:default', 'Pay Cycle • ');
    } 

    private static List<SIM_LookupSearchResult> getRecentlyViewed(String sObjectType, String icon, String titlePrefix) {
        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();
        
        List<RecentlyViewed> recentRecords = [
            SELECT Id, Name, Type
            FROM RecentlyViewed
            WHERE Type = :sObjectType
            ORDER BY LastViewedDate DESC
            LIMIT 5
        ];

        // Convert recent records into LookupSearchResult
        for (RecentlyViewed recentRecord : recentRecords) {
            results.add(
                    new SIM_LookupSearchResult(
                        recentRecord.Id,
                        sObjectType,
                        icon,
                        recentRecord.Name,
                        titlePrefix + recentRecord.Name
                    )
                );            
        }
        return results;
    }


    private static StatusInfo getStatusInfo(String batchId) {
        SIM_ManualTimesheetGeneration uploader = new SIM_ManualTimesheetGeneration(batchId);
        
        Manual_Timesheet_Generation__c mtg = uploader.getManualTimesheetGenerationRecord();        

        Integer progress=100;
        
        if (SIM_ManualTimesheetGeneration.UPLOAD_LOADING_STATUS  == mtg.Status__c) {
            if (mtg.Job_Id__c != null) {
                AsyncApexJob aSyncProgress = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus
                                              FROM AsyncApexJob 
                                              WHERE ID =:mtg.Job_Id__c
                                              LIMIT 1];
                
                
                if ((aSyncProgress.Status == 'Completed' && aSyncProgress.NumberOfErrors > 0) ||
                           aSyncProgress.Status == 'Aborted' ||aSyncProgress.Status == 'Failed') {
                    uploader.setFailStatus(aSyncProgress.ExtendedStatus);
                } else {                    
                    progress = Integer.valueOf((aSyncProgress.TotalJobItems > 0)? ((aSyncProgress.JobItemsProcessed/aSyncProgress.TotalJobItems)*100) : 100);
                }
            }
        }        

        return new StatusInfo(mtg.Status__c, progress);
    }

    public class StatusInfo {
        public String status;
        public Integer progress;
    
        public boolean isCompleted;
        public boolean isErrored;        
        public boolean isLoaded;
        public boolean hasLineErrors;
        
        public StatusInfo(String status, Integer progress) {
            this.status = status;
            this.progress = progress;
            this.isCompleted = (status == SIM_ManualTimesheetGeneration.UPLOAD_SUCCESS_STATUS || status == SIM_ManualTimesheetGeneration.UPLOAD_FAIL_STATUS
                                || status == SIM_ManualTimesheetGeneration.UPLOAD_DATAERROR_STATUS);
            this.hasLineErrors = (status == SIM_ManualTimesheetGeneration.UPLOAD_DATAERROR_STATUS);                        
            this.isErrored = (status == SIM_ManualTimesheetGeneration.UPLOAD_DATAERROR_STATUS || status == SIM_ManualTimesheetGeneration.UPLOAD_FAIL_STATUS);
            this.isLoaded = (status == SIM_ManualTimesheetGeneration.UPLOAD_SUCCESS_STATUS);            
        }
    }
}