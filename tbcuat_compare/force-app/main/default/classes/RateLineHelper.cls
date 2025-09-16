/**
* @description Helper class for Rate Lines
**/
public with sharing class RateLineHelper {

    public static Map<String, Salary_Threshold__mdt> salaryThresholdsByDeveloperNameMap;
    public static Salary_Threshold__mdt defaultSalaryThreshold;
    public static final String SALARY_THRESHOLD_FIELD = 'Job_Role_Name__c';


    static {
        salaryThresholdsByDeveloperNameMap = RateModifierHelper.salaryThresholdsByDeveloperNameMap;
        defaultSalaryThreshold = RateModifierHelper.defaultSalaryThreshold;
    }

    /**
    * @description Method to manage rate lines
    **/
    public static void manageRateLines(List<sirenum__Rate_Line__c> rateLinesList, Map<Id, sirenum__Rate_Line__c> rateLinesMap) {
        Set<sirenum__Rate_Line__c> eligibleRateLinesList = new Set<sirenum__Rate_Line__c>();
        for (sirenum__Rate_Line__c rateLine : rateLinesList) {
            if (rateLinesMap == null || (rateLinesMap != null && (rateLine.sirenum__Pay_Rate__c != rateLinesMap.get(rateLine.Id).sirenum__Pay_Rate__c
                || rateLine.sirenum__Charge_Rate__c != rateLinesMap.get(rateLine.Id).sirenum__Charge_Rate__c))) {
                eligibleRateLinesList.add(rateLine);
            }
        }
        if (!eligibleRateLinesList.isEmpty()) validateSalaryThresholds(new List<sirenum__Rate_Line__c>(eligibleRateLinesList));
    }   
    
    /**
    * @description Method to validate salary thresholds
    **/
    public static void validateSalaryThresholds(List<sirenum__Rate_Line__c> eligibleRateLinesList) {
        Map<Id, sirenum__Rate_Line__c> rateLinesMap = new Map<Id, sirenum__Rate_Line__c>(eligibleRateLinesList);
        List<sirenum__Rate_Line__c> rateLinesList = [SELECT Id, sirenum__Pay_Rate__c, sirenum__Charge_Rate__c, 
            sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c, sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c, sirenum__Rate_Card_Page__r.sirenum__Condition_value__c,
            sirenum__Standard_Rate_Type__c, sirenum__Standard_Rate_Type__r.ValidationEnabled__c, sirenum__Code__c
            FROM sirenum__Rate_Line__c WHERE Id IN: eligibleRateLinesList];
        for (sirenum__Rate_Line__c rateLine : rateLinesList) {            
            if ((rateLine.sirenum__Standard_Rate_Type__c == null || rateLine.sirenum__Standard_Rate_Type__r?.ValidationEnabled__c)
                && !String.isBlank(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c)
                && rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c.equals(SALARY_THRESHOLD_FIELD)
                && !String.isBlank(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c)
                && rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c.equalsIgnoreCase('Equal to')
                && !String.isBlank(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c)
                && RateModifierHelper.getThresholdByConditionValue(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c) != null) {
                if (rateLine.sirenum__Pay_Rate__c < RateModifierHelper.getThresholdByConditionValue(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c).Minimum_Rate__c) {
                    rateLinesMap.get(rateLine.Id).addError(
                        rateLine.sirenum__Code__c+' > This Rate Line is associated with a rate card page that specifies a minimum rate threshold of ' +
                        RateModifierHelper.getThresholdByConditionValue(rateLine.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c).Minimum_Rate__c
                    );
                }
            } else if (defaultSalaryThreshold != null && (rateLine.sirenum__Standard_Rate_Type__c == null || rateLine.sirenum__Standard_Rate_Type__r?.ValidationEnabled__c)) {
                if (rateLine.sirenum__Pay_Rate__c < defaultSalaryThreshold.Minimum_Rate__c) {
                    rateLinesMap.get(rateLine.Id).addError(
                        rateLine.sirenum__Code__c+' > This Rate Line is associated with a rate card page that specifies a minimum rate threshold of ' +
                        defaultSalaryThreshold.Minimum_Rate__c
                    );
                }
            }
        }
    }   
}