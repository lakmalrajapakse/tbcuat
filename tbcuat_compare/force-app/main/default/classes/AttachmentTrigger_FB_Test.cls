@isTest
public class AttachmentTrigger_FB_Test {
    @isTest
    public static void testAttachmentTrigger() {        
        // Create and insert an Account
        Account acc = new Account();
        acc.Name = 'Test';
        acc.TR1__Status__c = 'Credit Alert';
        acc.BillingCity = 'test';
        acc.BillingCountry = 'United Kingdom';
        acc.BillingPostalCode = '123123';
        acc.BillingStreet = 'UK';
        insert acc;
        
        System.assertNotEquals(null, acc.Id, 'Account should be inserted successfully');

        // Create and insert a Contact
        Contact con = new Contact();
        con.LastName = 'ACB';
        con.FirstName = 'XYZ';
        con.AccountId = acc.Id;
        con.Email = 'test@gmail.com';
        insert con;

        System.assertNotEquals(null, con.Id, 'Contact should be inserted successfully');

        // Create and insert a Job
        TR1__Job__c job = new TR1__Job__c();
        job.TR1__Contact__c = con.Id;
        job.Name = 'Test Dev';
        job.RecordTypeId = Schema.SObjectType.Tr1__Job__c.getRecordTypeInfosByName().get('Shift Work').getRecordTypeId();
        job.TR1__Account__c = acc.Id;
        insert job;

        System.assertNotEquals(null, job.Id, 'Job should be inserted successfully');

        // Create and insert a Job Board Application
        TR1__Job_Board_Application__c jba = new TR1__Job_Board_Application__c();
        jba.TR1__Job__c = job.Id;
        jba.TR1__Applicant__c = con.Id;
        insert jba;

        System.assertNotEquals(null, jba.Id, 'Job Board Application should be inserted successfully');

        // Create and insert an Attachment
        Attachment attach = new Attachment();    
        attach.Name = 'VRT__Resume_1729521265-19103-test.pdf';
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        attach.Body = bodyBlob;
        attach.ParentId = con.Id;
        attach.ContentType = 'application/pdf';
        insert attach;

        System.assertNotEquals(null, attach.Id, 'Attachment should be inserted successfully');

        // Create and insert a Contact Document
        TR1__ContactDocument__c cdd = new TR1__ContactDocument__c();    
        cdd.Name = 'VRT__Resume_1729521265-19103-test.pdf';
        cdd.TR1__ContentDocumentId__c = attach.Id;
        cdd.TR1__ContentVersionId__c = attach.Id;
        cdd.TR1__AttachmentId_Legacy__c = attach.Id;
        cdd.TR1__Internal_URL__c = 'abc'; 
        cdd.TR1__Contact__c = con.Id;
        insert cdd;

        System.assertNotEquals(null, cdd.Id, 'Contact Document should be inserted successfully');

        // Create and insert a ContentVersion
        ContentVersion contentVersion_1 = new ContentVersion();
        contentVersion_1.Title = 'Penguins';
        contentVersion_1.PathOnClient = 'Penguins.jpg';
        contentVersion_1.VersionData = Blob.valueOf('Test Content');
        contentVersion_1.IsMajorVersion = true;
        insert contentVersion_1;

        System.assertNotEquals(null, contentVersion_1.Id, 'ContentVersion should be inserted successfully');

        // Query ContentVersion and ContentDocument
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        System.assertEquals('Penguins', contentVersion_2.Title, 'ContentVersion title should match');

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assert(documents.size() > 0, 'There should be at least one ContentDocument');
    }
}