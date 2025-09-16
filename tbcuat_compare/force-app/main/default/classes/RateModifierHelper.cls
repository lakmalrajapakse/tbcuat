/**
* @description Helper class for Rate Modifiers
**/
public with sharing class RateModifierHelper {

    public static Map<String, Salary_Threshold__mdt> salaryThresholdsByDeveloperNameMap;
    public static Salary_Threshold__mdt defaultSalaryThreshold;
    public static final String SALARY_THRESHOLD_FIELD = 'Job_Role_Name__c';

    static {
        salaryThresholdsByDeveloperNameMap = getSalaryThresholdsByDeveloperNameMap();
    }
    
    /**
    * @description Method to manage rate modifiers
    **/
    public static void manageRateModifiers(List<sirenum__Rate_Modifier__c> rateModifiersList, Map<Id, sirenum__Rate_Modifier__c> rateModifiersMap) {
        Set<sirenum__Rate_Modifier__c> eligibleRateModifiersList = new Set<sirenum__Rate_Modifier__c>();
        for (sirenum__Rate_Modifier__c rateModifier : rateModifiersList) {
            if (rateModifiersMap == null || (rateModifiersMap != null && (rateModifier.sirenum__Pay_Rate__c != rateModifiersMap.get(rateModifier.Id).sirenum__Pay_Rate__c
                || rateModifier.sirenum__Charge_Rate__c != rateModifiersMap.get(rateModifier.Id).sirenum__Charge_Rate__c))) {
                eligibleRateModifiersList.add(rateModifier);
            }
        }
        if (!eligibleRateModifiersList.isEmpty()) validateSalaryThresholds(new List<sirenum__Rate_Modifier__c>(eligibleRateModifiersList));
    }   

    /**
    * @description Method to validate salary thresholds
    **/
    public static void validateSalaryThresholds(List<sirenum__Rate_Modifier__c> eligibleRateModifiersList) {
        Map<Id, sirenum__Rate_Modifier__c> rateModifiersMap = new Map<Id, sirenum__Rate_Modifier__c>(eligibleRateModifiersList);
        List<sirenum__Rate_Modifier__c> rateModifiersList = [SELECT Id, sirenum__Pay_Rate__c, sirenum__Charge_Rate__c, sirenum__Rate_Line__r.sirenum__Code__c,
            sirenum__Rate_Line__r.sirenum__Standard_Rate_Type__r.ValidationEnabled__c, sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c, 
            sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c, sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c, sirenum__Rate_Modifier_Type__r.Name 
            FROM sirenum__Rate_Modifier__c WHERE Id IN: eligibleRateModifiersList];
        for (sirenum__Rate_Modifier__c rateModifier : rateModifiersList) {
            if (((rateModifier.sirenum__Rate_Line__r.sirenum__Standard_Rate_Type__r.ValidationEnabled__c == null || rateModifier.sirenum__Rate_Line__r.sirenum__Standard_Rate_Type__r.ValidationEnabled__c))
                && !String.isBlank(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c)
                && rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Field__c.equals(SALARY_THRESHOLD_FIELD)
                && !String.isBlank(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c)
                && rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_Operator__c.equalsIgnoreCase('Equal To')
                && !String.isBlank(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c) 
                && getThresholdByConditionValue(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c) != null) {
                if (rateModifier.sirenum__Pay_Rate__c < getThresholdByConditionValue(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c).Minimum_Rate__c) {
                    rateModifiersMap.get(rateModifier.Id).addError(
                        rateModifier.sirenum__Rate_Line__r.sirenum__Code__c+' > Rate Modifier ('+rateModifier.sirenum__Rate_Modifier_Type__r.Name+') is associated with a rate card page that specifies a minimum rate threshold of ' +
                        getThresholdByConditionValue(rateModifier.sirenum__Rate_Line__r.sirenum__Rate_Card_Page__r.sirenum__Condition_value__c).Minimum_Rate__c
                    );
                }                
            } else if (defaultSalaryThreshold != null && (rateModifier.sirenum__Rate_Line__r.sirenum__Standard_Rate_Type__r.ValidationEnabled__c == null || rateModifier.sirenum__Rate_Line__r.sirenum__Standard_Rate_Type__r.ValidationEnabled__c)) {
                if (rateModifier.sirenum__Pay_Rate__c < defaultSalaryThreshold.Minimum_Rate__c) {
                    rateModifiersMap.get(rateModifier.Id).addError(
                        rateModifier.sirenum__Rate_Line__r.sirenum__Code__c+' > Rate Modifier ('+rateModifier.sirenum__Rate_Modifier_Type__r.Name+') is associated with a rate card page that specifies a minimum rate threshold of ' +
                        defaultSalaryThreshold.Minimum_Rate__c
                    );
                }
            }
        }
    }   

    /**
    * @description get Threshold by Codition Value
    **/
    public static Salary_Threshold__mdt getThresholdByConditionValue(String conditionValue) {
        if (String.isBlank(conditionValue)) return null;
        for (String key : salaryThresholdsByDeveloperNameMap.keySet()) {
            System.debug('Checking key: ' + key + ' against conditionValue: ' + conditionValue);
            // Check if the conditionValue contains the key
            if (conditionValue.contains(key)) {
                return salaryThresholdsByDeveloperNameMap.get(key);
            }
        }

        return null;        
    }

    /**
    * @description Method to get salary thresholds
    **/
    private static Map<String, Salary_Threshold__mdt> getSalaryThresholdsByDeveloperNameMap() {
        Map<String, Salary_Threshold__mdt> salaryThresholdsByDeveloperNameMap = new Map<String, Salary_Threshold__mdt>();
        for (Salary_Threshold__mdt salaryThreshold : [SELECT Id, DeveloperName, Minimum_Rate__c, IsDefault__c, label FROM Salary_Threshold__mdt]) {
            salaryThresholdsByDeveloperNameMap.put(salaryThreshold.label, salaryThreshold);
            if (salaryThreshold.IsDefault__c) defaultSalaryThreshold = salaryThreshold;
        }
        if (Test.isRunningTest()) {
            salaryThresholdsByDeveloperNameMap.put('Test_Threshold', new Salary_Threshold__mdt(
                DeveloperName = 'Test_Threshold',
                Minimum_Rate__c = 20
            ));
            defaultSalaryThreshold = new Salary_Threshold__mdt(
                DeveloperName = 'Default_Threshold',

                Minimum_Rate__c = 20,
                IsDefault__c = true
            );
        }
        return salaryThresholdsByDeveloperNameMap;
    }
}