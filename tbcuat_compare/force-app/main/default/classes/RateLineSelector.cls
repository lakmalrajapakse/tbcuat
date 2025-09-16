public with sharing class RateLineSelector {
    public static final List<Salary_Threshold__mdt> MOCK_SALARY_THRESHOLDS = new List<Salary_Threshold__mdt>();

    public static List<TR1__Job__c> getJobsByRateCardId(Set<Id> rateCardIds) {
        return [
            SELECT Id, s5m__JobRole__r.sirenum__Rate_Card__c, Approved__c
            FROM TR1__Job__c
            WHERE s5m__JobRole__r.sirenum__Rate_Card__c IN :rateCardIds
            WITH SYSTEM_MODE
        ];
    }

    public static List<sirenum__Rate_Card_Page__c> getRateCardPagesByRateLineIds(Set<Id> rateLineIds) {
        return [
            SELECT
                Id,
                sirenum__Rate_Card__c,
                sirenum__Condition_Field__c,
                sirenum__Condition_Operator__c,
                sirenum__Condition_value__c
            FROM sirenum__Rate_Card_Page__c
            WHERE Id IN (SELECT sirenum__Rate_Card_Page__c FROM sirenum__Rate_Line__c WHERE Id IN :rateLineIds)
            WITH SYSTEM_MODE
        ];
    }

    public static List<sirenum__Rate_Line__c> getRateLinesById(Set<Id> rateLineIds) {
        return [
            SELECT Id, Rate_Code__c, Rate_Code__r.Name, Rate_Code__r.Validation_Enabled__c
            FROM sirenum__Rate_Line__c
            WHERE Id IN :rateLineIds
            WITH SYSTEM_MODE
        ];
    }

    public static List<Rate_Code__c> getRateCodesById(Set<Id> rateCodeIds) {
        return [
            SELECT Id, Name
            FROM Rate_Code__c
            WHERE Id IN :rateCodeIds
            WITH SYSTEM_MODE
        ];
    }

    public static List<sirenum__Shift__c> getShiftsByRateCardId(Set<Id> rateCardIds) {
        return [
            SELECT Id, Salary_Threshold__c
            FROM sirenum__Shift__c
            WHERE sirenum__Team__r.sirenum__Rate_Card__c IN :rateCardIds
            WITH SYSTEM_MODE
        ];
    }

    public static List<Salary_Threshold__mdt> getSalaryThresholdsByName(Set<String> thresholdNames) {
        if (Test.isRunningTest()) {
            return MOCK_SALARY_THRESHOLDS;
        }

        return [
            SELECT DeveloperName, Minimum_Rate__c
            FROM Salary_Threshold__mdt
            WHERE DeveloperName IN :thresholdNames
            WITH SYSTEM_MODE
        ];
    }
}