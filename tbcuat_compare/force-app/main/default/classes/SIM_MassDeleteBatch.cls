public with sharing class SIM_MassDeleteBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String objectName;
    private String filterCondition;
    public SIM_MassDeleteBatch(String objectName, String filterCondition) {
        this.objectName = objectName;
        this.filterCondition = filterCondition;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String queryString = 'SELECT Id FROM {0} WHERE {1}';
        return Database.getQueryLocator(String.format(queryString, new Object[]{
            this.objectName,
            filterCondition != null ? filterCondition : 'ID != null'
        }));
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext context) {
        
    }
}