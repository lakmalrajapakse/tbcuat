public with sharing class JobSelector {
    public static List<TR1__Job__c> getJobsByJobId(Set<Id> jobIds) {
        return [
            SELECT Id, s5m__JobRole__r.sirenum__Rate_Card__c
            FROM TR1__Job__c
            WHERE Id IN :jobIds
            WITH USER_MODE
        ];
    }

    public static List<sirenum__Rate_Card_Page__c> getRateCardPagesByRateCardIds(Set<Id> rateCardIds) {
        return [
            SELECT Id, sirenum__Rate_Card__c, (SELECT Id, sirenum__Rate_Card_Page__c FROM sirenum__Rate_Lines__r)
            FROM sirenum__Rate_Card_Page__c
            WHERE sirenum__Rate_Card__c IN :rateCardIds
            WITH USER_MODE
        ];
    }

    public static Set<Job_Rate_Line__c> getJobRateLinesByJobIdForComparison(Set<Id> jobIds) {
        List<Job_Rate_Line__c> queriedJrls = [
            SELECT Id, Rate_Line__c, Rate_Card_Page__c, Job__c
            FROM Job_Rate_Line__c
            WHERE Job__c IN :jobIds
            WITH USER_MODE
        ];

        Set<Job_Rate_Line__c> results = new Set<Job_Rate_Line__c>();

        for (Job_Rate_Line__c jrl : queriedJrls) {
            results.add(
                new Job_Rate_Line__c(
                    Rate_Line__c = jrl.Rate_Line__c,
                    Rate_Card_Page__c = jrl.Rate_Card_Page__c,
                    Job__c = jrl.Job__c
                )
            );
        }

        return results;
    }
}