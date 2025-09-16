global class ProcessJobShiftScheduler implements Schedulable{    
    /**
    * @description Execute method
    **/
    global void execute(SchedulableContext schedulableContext) {        
        List<sirenum__AdaptiveBatchSettings__c> createShiftJob = [select name, sirenum__ChunkSize__c from sirenum__AdaptiveBatchSettings__c where sirenum__Classname__c = 's5m.BH4SFCreateShiftDemandsForJobs' and sirenum__Enabled__c = true limit 1];

        if (createShiftJob.isEmpty()) {
            return;
        }

        Database.executeBatch(new ProcessJobShiftBatch(createShiftJob[0].name), (createShiftJob[0].sirenum__ChunkSize__c != null) ? Integer.valueOf(createShiftJob[0].sirenum__ChunkSize__c) : 20);
    }
}