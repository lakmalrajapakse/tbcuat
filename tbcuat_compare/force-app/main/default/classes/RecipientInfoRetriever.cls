/**
 * RecipientInfoRetriever is a class that retrieves recipient information for messaging purposes.
 * It provides functionality to get recipient details, template options for messaging, and the
 * body of a specific template. It is designed to be used with Salesforce Aura components,
 * hence the use of the @AuraEnabled annotation.
 */
public with sharing class RecipientInfoRetriever {

    /**
     * Retrieves a list of ContactWrapper objects based on provided record IDs.
     * It checks against mass messaging settings and determines whether SMS, Email,
     * or Push notifications are enabled for each contact.
     *
     * @param recordIds A list of record IDs for which recipient information is requested.
     * @return A JSON serialized string representing a SuccessResponse with the list of ContactWrappers.
     */
    @AuraEnabled
    public static String getRecepients(List<String> recordIds) {
        // Retrieve the mass messaging settings from a custom settings object.
        Mass_Message_Manager__c settings = Mass_Message_Manager__c.getInstance();

        // Initialize an empty list to hold wrapped contact information.
        List<ContactWrapper> wrappedContacts = new List<ContactWrapper>();

        // Query the Contact object for records matching the provided IDs and specific fields.
        List<Contact> contacts = [
            SELECT Id, Name, FirstName, LastName, MobilePhone, Phone, HomePhone, OtherPhone,
                Email
            FROM Contact
            WHERE Id IN :recordIds
        ];

        // If no contacts are found, return an empty list of wrappedContacts.
        if (contacts.isEmpty()) {
            return JSON.serialize(new Response.SuccessResponse(wrappedContacts));
        }

        // Iterate through each contact record to determine the communication options available.
        for (Contact c : contacts) {
            // Determine if SMS is disabled based on the presence of a mobile phone number.
            Boolean disableSMS = c.MobilePhone == null;

            // Determine if Email is disabled based on the presence of an email address.
            Boolean disableEmail = c.Email == null;

            // Determine if App notifications are disabled based on the presence of a push notification ID.
            //Boolean disableApp = c.sirenum__Push_Notification_Id__c == null;

            // Set default communication preferences based on the mass messaging settings and whether they are disabled.
            Boolean sendSMSDefault = settings.Enable_SMS__c && !disableSMS;
            Boolean sendEmailDefault = settings.Enable_Email__c && !disableEmail;

            // Add a new ContactWrapper to the list with the determined preferences.
            wrappedContacts.add(new ContactWrapper(c, disableSMS, disableEmail,
                sendSMSDefault, sendEmailDefault));
        }
        // Return the list of ContactWrappers as a JSON serialized SuccessResponse object.
        return JSON.serialize(new Response.SuccessResponse(wrappedContacts));
    }

    /**
     * Retrieves template options for messaging from a specific folder named 'SMS'.
     *
     * @return A JSON serialized string representing a SuccessResponse with a list of template options.
     */
    @AuraEnabled
    public static String getTemplateOptions() {
        // Define a constant for the default folder name where templates are stored.
        final String DEFAULT_SMS_FOLDER = 'SMS';

        // Query the EmailTemplate object for templates within the specified folder.
        List<EmailTemplate> ets = [
            SELECT Id, Body, Name, Description
            FROM EmailTemplate
            WHERE Folder.Name = :DEFAULT_SMS_FOLDER
        ];

        // Initialize an empty list to hold SelectOption objects representing each template.
        List<SelectOption> options = new List<SelectOption>();

        // Iterate through each EmailTemplate to create SelectOption objects.
        for (EmailTemplate et : ets) {
            options.add(new SelectOption(et.Id, et.Name));
        }

        // Return the list of SelectOptions as a JSON serialized SuccessResponse object.
        return JSON.serialize(new Response.SuccessResponse(options));
    }

    /**
     * Retrieves the body of an email template based on a provided template ID.
     *
     * @param templateId The ID of the template for which the body is requested.
     * @return A JSON serialized string representing a SuccessResponse with the template body.
     */
    @AuraEnabled
    public static String getTemplateBody(Id templateId) {
        // Query the EmailTemplate object for a specific template by ID.
        List<EmailTemplate> ets = [
            SELECT Id, Body, Name, Description
            FROM EmailTemplate
            WHERE Id = :templateId
        ];

        // Initialize an empty string to hold the template body.
        String templateBody = '';

        // If a template is found, set the templateBody to the Body of the first template.
        if (!ets.isEmpty()) {
            templateBody = ets[0].Body;
        }

        // Return the template body as a JSON serialized SuccessResponse object.
        return JSON.serialize(new Response.SuccessResponse(templateBody));
    }
}


// The RecipientInfoRetriever class contains three methods:

// getRecepients: Takes a list of record IDs and returns a serialized JSON string with a list of 
// ContactWrapper objects, each representing a contact with their communication options based on system settings.

// getTemplateOptions: Retrieves available email template options from a specific folder
//  and returns them as a serialized JSON string.

// getTemplateBody: Fetches the body of an email template given its ID and returns 
// it as a serialized JSON string.

// Each method is annotated with @AuraEnabled to make it callable from a Lightning 
// component within the Salesforce platform.