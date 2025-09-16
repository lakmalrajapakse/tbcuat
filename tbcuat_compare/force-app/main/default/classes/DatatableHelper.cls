/**
*   @description : Helper class for datatable
**/
public with sharing class DatatableHelper {
    
    /**
    *   @description : Method to get plan codes
    **/
    public static List<String> getPlanCodes() {
        List<String> planCodesList = new List<String>();
        for (Picklist_Library__c planCode : [SELECT Name FROM Picklist_Library__c 
            WHERE RecordTypeId =: Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId() ORDER BY Name]) {
            planCodesList.add(planCode.Name);
        }
        return planCodesList;
    }

    /**
    *   @description : Method to get plan codes for a branch
    **/
    public static List<String> getPlanCodesForBranches(Set<String> branchIds) {
        List<String> planCodesList = new List<String>();
        for (Picklist_Library__c planCode : [SELECT Name FROM Picklist_Library__c 
            WHERE RecordTypeId =: Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId() 
            AND Branch__c IN: branchIds ORDER BY Name]) {
            planCodesList.add(planCode.Name);
        }
        return planCodesList;
    }
}