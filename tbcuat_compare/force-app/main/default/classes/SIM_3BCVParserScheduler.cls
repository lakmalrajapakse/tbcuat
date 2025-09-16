Global with sharing class SIM_3BCVParserScheduler implements Schedulable, Database.AllowsCallouts {

    global void execute(SchedulableContext SC) {
        // Execute the batch job
        SIM_3BCVParserSchedulable batchJob = new SIM_3BCVParserSchedulable();
        Database.executeBatch(batchJob,1); // Process in batches of 200 records
    }

}