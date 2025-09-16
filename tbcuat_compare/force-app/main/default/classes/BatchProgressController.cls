public with sharing class BatchProgressController {
    @testVisible
    private static AsyncApexJob dummyJob;

    @AuraEnabled
    public static BatchDetail getBatchProgress(Id batchId) {
        AsyncApexJob job = dummyJob != null
            ? dummyJob
            : [
                  SELECT Id, JobItemsProcessed, TotalJobItems, NumberOfErrors, Status, ExtendedStatus
                  FROM AsyncApexJob
                  WHERE Id = :batchId
                  WITH SYSTEM_MODE
              ];

        BatchDetail detail = new BatchDetail();

        detail.JobItemsProcessed = job.JobItemsProcessed;
        detail.TotalJobItems = job.TotalJobItems;
        detail.NumberOfErrors = job.NumberOfErrors;
        detail.Status = job.Status;
        detail.ExtendedStatus = job.ExtendedStatus;

        return detail;
    }

    public class BatchDetail {
        @AuraEnabled
        public Integer JobItemsProcessed;
        @AuraEnabled
        public Integer TotalJobItems;
        @AuraEnabled
        public Integer NumberOfErrors;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String ExtendedStatus;
    }
}