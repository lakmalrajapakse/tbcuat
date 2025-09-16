public class JobSharingQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> jobIds;
    private SharingHelper.TriggerContext context;
    private List<SObject> recordsList;
    private Map<Id, SObject> oldRecordsMap;
    private static final Integer SUB_BATCH_SIZE = 50;

    public JobSharingQueueable(
        List<Id> jobIds, 
        List<SObject> recordsList, 
        Map<Id, SObject> oldRecordsMap, 
        SharingHelper.TriggerContext context
    ) {
        this.jobIds = jobIds;
        this.recordsList = recordsList;
        this.oldRecordsMap = oldRecordsMap;
        this.context = context;
        System.debug('JobSharingQueueable initialized with ' + jobIds.size() + ' job IDs');
        System.debug('Trigger context: ' + context);
        System.debug('recordsList size: ' + (recordsList != null ? recordsList.size() : 0));
        System.debug('oldRecordsMap size: ' + (oldRecordsMap != null ? oldRecordsMap.size() : 0));
    }

    public void execute(QueueableContext qc) {
        for (Integer i = 0; i < jobIds.size(); i += SUB_BATCH_SIZE) {
            
            List<Id> chunk = new List<Id>();
            Integer endInt = Math.min(i + SUB_BATCH_SIZE, jobIds.size());
            for (Integer j = i; j < endInt; j++) {
                chunk.add(jobIds[j]);
            }

            List<TR1__Job__c> jobs = [
                SELECT Id, Plan_Code__c
                FROM TR1__Job__c
                WHERE Id IN :chunk
            ];

            if (!jobs.isEmpty()) {
                SharingHelper.manageSharing(
                    TR1__Job__c.sObjectType.getDescribe().getName(),
                    jobs,
                    oldRecordsMap,
                    context
                );
            }
        }
    }
}