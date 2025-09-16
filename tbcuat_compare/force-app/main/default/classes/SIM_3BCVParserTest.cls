@isTest
public class SIM_3BCVParserTest {

    Public static b3f__FormResponse__c formResponse;
    Public static Id contactId;
    Public static Boolean forceErrorInTest = false;

    @TestSetup
    static void setupData(){
        Contact c = new Contact(
            Firstname = 'Salesforce',
            LastName = 'Contact',
            Email = 'aa@aa.com'
        );
        insert c;

        b3f__Form__c form = new b3f__Form__c(
            Name = 'RegForm',
            Parse_CV_on_this_form__c = true,
            CV_Upload_Field_Ref__c = 'CV Upload_a6556'
        );
        insert form;

        b3f__FormResponse__c formResponse = new b3f__FormResponse__c(
            b3f__Type__c = 'PROCESSING',
            b3f__New_Record_ID__c = c.Id,
            b3f__Form__c = form.id
        );
        insert formResponse;

        // Create ContentVersion, which will create ContentDocument
        ContentVersion version = new ContentVersion(
            Title = 'Response.json',
            PathOnClient = 'Response.json',
            VersionData = Blob.valueOf('{\"CV Upload_a6556\":\"file,base64Data\"}'),
            FirstPublishLocationId = formResponse.Id // Associate ContentDocument with the FormResponse
        );
        insert version;        
    }

    @isTest
    static void testSendCVToParser() {

        // Update the Response To Complete
        List<b3f__FormResponse__c> formResponseList = [SELECT Id, b3f__Type__c, b3f__New_Record_ID__c, b3f__Form__c FROM b3f__FormResponse__c];
        formResponse = formResponseList[0];
        Test.startTest();
        formResponse.b3f__Type__c = 'COMPLETE';
        update formResponse;
        try {
            SIM_3BCVParser.sendCVToParser(new List<List<b3f__FormResponse__c>>{new List<b3f__FormResponse__c>{formResponse}});
        } catch (Exception e) {
            System.assert(e.getMessage().contains('CV Parsed sucessfully'));
        }
        Test.stopTest();

    }

    @isTest
    static void testSendCVToParserThrowError() {

        // Update the Response To Complete
        List<b3f__FormResponse__c> formResponseList = [SELECT Id, b3f__Type__c, b3f__New_Record_ID__c, b3f__Form__c FROM b3f__FormResponse__c];
        formResponse = formResponseList[0];
        Test.startTest();
        formResponse.b3f__Type__c = 'COMPLETE';
        SIM_3BCVParser.forceErrorInTest = true; // Set the flag to force an error
        update formResponse;
        try {
            SIM_3BCVParser.sendCVToParser(new List<List<b3f__FormResponse__c>>{new List<b3f__FormResponse__c>{formResponse}});
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error parsing CV'));
        }
        Test.stopTest();

    }

}