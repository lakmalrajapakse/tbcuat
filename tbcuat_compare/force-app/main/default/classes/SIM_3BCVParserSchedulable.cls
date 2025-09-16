global class SIM_3BCVParserSchedulable implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
        global Database.QueryLocator start(Database.BatchableContext BC) {
            List<AsyncApexJob> jobs = [
                SELECT Id, Status, JobType
                FROM AsyncApexJob
                WHERE JobType = 'BatchApex'
                AND Status IN ('Processing')
                AND ApexClass.Name = 'SIM_3BCVParserSchedulable'
            ];
            if(jobs.size() > 1) {
                system.debug('Job Already Running');
                return null;
            } else {
                // Query the records to process
                return Database.getQueryLocator('SELECT Id, b3f__New_Record_ID__c, b3f__Form__c FROM b3f__FormResponse__c WHERE Parse_this_Form_Response__c = true AND b3f__New_Record_ID__c != null');
            }
        }
    
        global void execute(Database.BatchableContext BC, List<b3f__FormResponse__c> scope) {
            // Process each batch of records
            for (b3f__FormResponse__c fr : scope) {
                SIM_3BCVParser.sendCVToParser(fr);
            }
        }
    
        global void finish(Database.BatchableContext BC) {
            // Final cleanup or logging
            System.debug('Batch Job Finished!');
        }
}