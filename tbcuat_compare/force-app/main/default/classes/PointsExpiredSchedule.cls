global class PointsExpiredSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Davis_Integration_Settings__c integrationSettings = Davis_Integration_Settings__c.getInstance();
        Integer maxTickets = integrationSettings.Points_Expired_Batch_Size__c != null 
                                      ? (Integer) integrationSettings.Points_Expired_Batch_Size__c
                                      : 200;
        PointsExpiredBatch batch = new PointsExpiredBatch();
        Database.executeBatch(batch, maxTickets);
    }
}