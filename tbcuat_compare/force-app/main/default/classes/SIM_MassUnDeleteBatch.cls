public with sharing class SIM_MassUnDeleteBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String objectName;
    private String filterCondition;
    public SIM_MassUnDeleteBatch(String objectName, String filterCondition) {
        this.objectName = objectName;
        this.filterCondition = filterCondition;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String queryString = 'SELECT Id FROM {0} WHERE {1} AND IsDeleted = true ALL ROWS';
        return Database.getQueryLocator(String.format(queryString, new Object[]{
            this.objectName,
            filterCondition != null ? filterCondition : 'ID != null'
        }));
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        Database.undelete(scope, false);
    }

    public void finish(Database.BatchableContext context) {
        
    }
}