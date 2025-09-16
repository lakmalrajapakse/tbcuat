/**
 * ContactWrapper is a class that encapsulates the details of a Contact record along with
 * various flags indicating the status of communication preferences such as SMS, Email,
 * and Push notifications. This wrapper class is typically used to manage and transport
 * Contact data along with related actions within Apex code, such as in controllers or batch processes.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 */
public with sharing class ContactWrapper {
    
    // Status of the contact processing or any other relevant status.
    public String status;
    
    // The Salesforce ID of the contact record.
    public String conId;
    
    // The Contact record that this wrapper represents.
    public Contact contact;
    
    // Flag to indicate if an SMS should be sent to the contact.
    public Boolean sendSMS;
    
    // Flag to indicate if the option to send an SMS is disabled.
    public Boolean sendSMSDisabled;
    
    // Flag to indicate if an Email should be sent to the contact.
    public Boolean sendEmail;
    
    // Flag to indicate if the option to send an Email is disabled.
    public Boolean sendEmailDisabled;
    
    // Flag to indicate if a Push notification should be sent to the contact.
    public Boolean sendPush;
    
    // Flag to indicate if the option to send a Push notification is disabled.
    public Boolean sendPushDisabled;
    
    // Type of communication or action being taken with this wrapper.
    public String type;
    
    // Result of the communication action taken, if applicable.
    public String result;
    
    // Message details or additional information about the communication action.
    public String message;
    public ContactWrapper() {
        this.sendSMS = false;
        this.sendEmail = false;
        this.sendPush = false;
        this.sendSMSDisabled = false;
        this.sendEmailDisabled = false;
        this.sendPushDisabled = false;
        this.message = '';
        this.contact = new Contact();
        this.conId = '';
    }
    /**
     * Constructor for ContactWrapper that initializes the object with contact information
     * and communication preferences.
     *
     * @param contact The Contact record that this wrapper is for.
     * @param smsStatus The status indicating if SMS functionality is disabled.
     * @param emailStatus The status indicating if Email functionality is disabled.
     * @param pushStatus The status indicating if Push notification functionality is disabled.
     * @param sendSMSDefault The default value indicating if an SMS should be sent.
     * @param sendEmailDefault The default value indicating if an Email should be sent.
     * @param sendPushDefault The default value indicating if a Push notification should be sent.
     */
    public ContactWrapper(Contact contact, Boolean smsStatus, Boolean emailStatus, Boolean pushStatus,
                          Boolean sendSMSDefault, Boolean sendEmailDefault, Boolean sendPushDefault) {
        this.sendSMS = sendSMSDefault;
        this.sendEmail = sendEmailDefault;
        this.sendPush = sendPushDefault;
        this.sendSMSDisabled = smsStatus;
        this.sendEmailDisabled = emailStatus;
        this.sendPushDisabled = pushStatus;
        this.message = '';
        this.contact = contact;
        this.conId = contact.Id; // Assigning the Salesforce ID of the contact record.
    }

    public ContactWrapper(Contact contact, Boolean smsStatus, Boolean emailStatus,
                          Boolean sendSMSDefault, Boolean sendEmailDefault) {
        this.sendSMS = sendSMSDefault;
        this.sendEmail = sendEmailDefault;
        this.sendPush = false;
        this.sendSMSDisabled = smsStatus;
        this.sendEmailDisabled = emailStatus;
        this.sendPushDisabled = false;
        this.message = '';
        this.contact = contact;
        this.conId = contact.Id; // Assigning the Salesforce ID of the contact record.
    }
}