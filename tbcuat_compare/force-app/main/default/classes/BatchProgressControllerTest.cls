@isTest
public class BatchProgressControllerTest {
    @isTest
    static void getBatchProgress_returnsBatchDetailDto() {
        // Given
        AsyncApexJob dummyJob = (AsyncApexJob) JSON.deserialize(
            '{ "JobItemsProcessed" : 1, "TotalJobItems" : 2, "NumberOfErrors" : 3, "Status": "Pending" }',
            AsyncApexJob.class
        );

        BatchProgressController.dummyJob = dummyJob;

        // When
        BatchProgressController.BatchDetail response = BatchProgressController.getBatchProgress(
            dummyJob.Id
        );

        // Then
        System.assertEquals(
            dummyJob.JobItemsProcessed,
            response.JobItemsProcessed,
            'Response should contain correct value for SObject record'
        );
        System.assertEquals(
            dummyJob.TotalJobItems,
            response.TotalJobItems,
            'Response should contain correct value for SObject record'
        );
        System.assertEquals(
            dummyJob.NumberOfErrors,
            response.NumberOfErrors,
            'Response should contain correct value for SObject record'
        );
        System.assertEquals(
            dummyJob.Status,
            response.Status,
            'Response should contain correct value for SObject record'
        );
    }
}