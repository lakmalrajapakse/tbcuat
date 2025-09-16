public with sharing class ProcessJobShiftBatch implements Database.Batchable<SObject>{    
    String adaptiveBatchName;

    public ProcessJobShiftBatch(String adaptiveBatchName) {
        this.adaptiveBatchName = adaptiveBatchName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {        
        return Database.getQueryLocator([
            SELECT id, s5m__GenerationLastRequired__c 
            from TR1__Job__c
            where s5m__PendingDemandGeneration__c = false
            and s5m__ShiftDemandGeneration__c = 'Ongoing' 
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {        
        List<TR1__Job__c> jobs = (List<TR1__Job__c>)scope;
        Datetime lastRequired = Datetime.now();

        for (TR1__Job__c job : jobs) {
            job.s5m__GenerationLastRequired__c = lastRequired;
        }

        update jobs;
    }

    
    public void finish(Database.BatchableContext bc) {
        sirenum.AdaptiveInvoker.invokeBatch(this.adaptiveBatchName);
    }
}