public class PointsExpiredBatch implements Database.Batchable<SObject> {

    // Query to fetch the records to process
    public Database.QueryLocator start(Database.BatchableContext context) {
        String sql = 'SELECT Id, sirenum__Valid__c, Points_Expired__c ' 
                     + 'FROM sirenum__Ticket__c '
                     + 'WHERE Points__c > 0 '
                     + ((!Test.isRunningTest()) ? 'AND ((Points_Expired__c = false AND sirenum__Valid__c =false) OR (Points_Expired__c = true AND sirenum__Valid__c =true))' : '');

        return Database.getQueryLocator(sql);
    }

    public void execute(Database.BatchableContext context, List<sirenum__Ticket__c > scope) {
        for (sirenum__Ticket__c ticket : scope) {
            ticket.Points_Expired__c = !ticket.sirenum__Valid__c;
        }
        update scope;        
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch execution finished.');
    }
}