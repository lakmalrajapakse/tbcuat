public inherited sharing class RateLineTriggerHandler {
    public static void onBeforeInsertAll(List<sirenum__Rate_Line__c> newLines) {     
    }

    public static void onAfterInsertAll(List<sirenum__Rate_Line__c> newLines) {
        RateLineHelper.manageRateLines(newLines, null);
    }

    public static void onBeforeUpdateAll(
        Map<Id, sirenum__Rate_Line__c> oldRateLines,
        Map<Id, sirenum__Rate_Line__c> newRateLines
    ) {
    }

    public static void onAfterUpdateAll(
        Map<Id, sirenum__Rate_Line__c> oldRateLines,
        Map<Id, sirenum__Rate_Line__c> newRateLines
    ) {
        RateLineHelper.manageRateLines(newRateLines.values(), oldRateLines);
    }
}