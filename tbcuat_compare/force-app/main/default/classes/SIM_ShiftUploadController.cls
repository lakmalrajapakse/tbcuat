public with sharing class SIM_ShiftUploadController {

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
        for (Shift_Upload_Template__mdt template : [select DeveloperName, MasterLabel from Shift_Upload_Template__mdt order by MasterLabel]) {
            templates.add(new SIM_Option(template.DeveloperName, template.MasterLabel));
        }        
        
        return JSON.serialize(templates);
    } 

    @AuraEnabled
    public static String loadData(String template, String filename, Integer hrow, Integer drow, String jsonString) {        
        String batchProcessId;
        try {
            System.debug(filename + ' : ' + template + ' : ' + hrow + ' : ' + drow + ' : ' + jsonString);
            SIM_ShiftUploader uploader = new SIM_ShiftUploader(filename, template, hrow, drow);
            batchProcessId = uploader.submitBatch(jsonString);
        } catch (Exception e){
            return JSON.serialize(new SIM_Response.ErrorResponse('Error: ' + e.getMessage() + ' - ' + e.getLineNumber()));            
        }
        
        return JSON.serialize(new SIM_Response.SuccessResponse(batchProcessId));
    }

    private static StatusInfo getStatusInfo(String batchId) {
        SIM_ShiftUploader uploader = new SIM_ShiftUploader(batchId);
        
        Bulk_Shift_Upload__c bsu = uploader.getBulkShiftUploadRecord();        

        Integer progress=100;
        
        if (SIM_ShiftUploader.UPLOAD_LOADING_STATUS  == bsu.Status__c) {
            if (bsu.Job_Id__c != null) {
                AsyncApexJob aSyncProgress = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus
                                              FROM AsyncApexJob 
                                              WHERE ID =:bsu.Job_Id__c
                                              LIMIT 1];
                
                
                if ((aSyncProgress.Status == 'Completed' && aSyncProgress.NumberOfErrors > 0) ||
                           aSyncProgress.Status == 'Aborted' ||aSyncProgress.Status == 'Failed') {
                    uploader.setFailStatus(aSyncProgress.ExtendedStatus);
                } else {                    
                    progress = Integer.valueOf((aSyncProgress.TotalJobItems > 0)? ((aSyncProgress.JobItemsProcessed/aSyncProgress.TotalJobItems)*100) : 100);
                }
            }
        }        

        return new StatusInfo(bsu.Status__c, progress);
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
            this.isCompleted = (status == SIM_ShiftUploader.UPLOAD_SUCCESS_STATUS || status == SIM_ShiftUploader.UPLOAD_FAIL_STATUS
                                || status == SIM_ShiftUploader.UPLOAD_DATAERROR_STATUS);
            this.hasLineErrors = (status == SIM_ShiftUploader.UPLOAD_DATAERROR_STATUS);                        
            this.isErrored = (status == SIM_ShiftUploader.UPLOAD_DATAERROR_STATUS || status == SIM_ShiftUploader.UPLOAD_FAIL_STATUS);
            this.isLoaded = (status == SIM_ShiftUploader.UPLOAD_SUCCESS_STATUS);            
        }
    }
}