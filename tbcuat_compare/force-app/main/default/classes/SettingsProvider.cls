public class SettingsProvider {
    @AuraEnabled(cacheable=true)
    public static TextIUS_Settings__c getSettings() {
        return TextIUS_Settings__c.getInstance();
    }
}