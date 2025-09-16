global class DAVIS_CheckDrivingLicenseScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Davis_Integration_Settings__c integrationSettings = Davis_Integration_Settings__c.getInstance();
        Integer maxContacts = integrationSettings.Max_Contacts_Per_Run__c != null 
                                      ? (Integer) integrationSettings.Max_Contacts_Per_Run__c 
                                      : 10;
        DAVIS_CheckDrivingLicenseBatch batch = new DAVIS_CheckDrivingLicenseBatch();
        Database.executeBatch(batch, maxContacts);
    }
}