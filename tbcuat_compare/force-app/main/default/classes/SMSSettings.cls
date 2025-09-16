public class SMSSettings {
    public String apiToken { get; private set; }
    public String senderPhoneNumber { get; private set; }
    public String apiUrl { get; private set; }
    public Integer smsEventDescriptionLength { get; private set; }
    public String greetings { get; private set; }
    public String adminId { get; private set; }
    public String adminName { get; private set; }
    public String textUsPrivateKey { get; private set; }

    public SMSSettings() {
        // Load configuration from TextIUS_Settings Custom Settings
        TextIUS_Settings__c settings = SettingsProvider.getSettings();
        apiToken = settings.API_Token__c;
        senderPhoneNumber = settings.Sender_Phone_Number__c;
        apiUrl = settings.API_URL__c;
        smsEventDescriptionLength = (Integer) settings.SMS_Event_Description_Length__c;
        greetings = settings.Greetings__c;
        adminId = settings.Default_Admin_Id__c;
        adminName = settings.Default_Name__c;
        textUsPrivateKey = settings.textus_privatekey__c;
    }

    public static SMSSettings getInstance() {
        return new SMSSettings();
    }
}