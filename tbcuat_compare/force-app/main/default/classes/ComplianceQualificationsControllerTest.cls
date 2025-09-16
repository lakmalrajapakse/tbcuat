@isTest
public with sharing class ComplianceQualificationsControllerTest {
    @isTest
    static void getQualifications_returnsCorrectData() {
        sirenum__TicketType__c competency1 = new sirenum__TicketType__c(
            Name = 'Test Competency 1',
            Competency_Category__c = 'General',
            sirenum__Requires_Proof__c = true,
            sirenum__Expires__c = false
        );

        sirenum__TicketType__c competency2 = new sirenum__TicketType__c(
            Name = 'Test Competency 2',
            Competency_Category__c = 'Driver Licenses',
            sirenum__Requires_Proof__c = true,
            sirenum__Expires__c = false
        );

        insert new List<SObject>{ competency1, competency2 };

        Contact candidate1 = new Contact(FirstName = 'Bob', LastName = 'Dobbery');
        Contact candidate2 = new Contact(FirstName = 'Bill', LastName = 'Jones');
        insert new List<SObject>{ candidate1, candidate2 };

        sirenum__Ticket__c qualification1 = new sirenum__Ticket__c(
            sirenum__Valid_from__c = Date.newInstance(2025, 1, 1),
            sirenum__Valid_until__c = Date.newInstance(2025, 5, 1),
            sirenum__TicketType__c = competency2.Id,
            sirenum__Owner__c = candidate1.Id
        );

        sirenum__Ticket__c qualification2 = new sirenum__Ticket__c(
            sirenum__Valid_from__c = Date.newInstance(2025, 5, 1),
            sirenum__Valid_until__c = Date.newInstance(2025, 6, 1),
            sirenum__TicketType__c = competency1.Id,
            sirenum__Owner__c = candidate2.Id
        );

        insert new List<SObject>{ qualification1, qualification2 };

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        contentVersion.PathOnClient = 'TestFile';
        contentVersion.Title = 'TestFile';
        contentVersion.VersionData = Blob.valueOf('Test Content');
        insert contentVersion;

        contentVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            WITH USER_MODE
        ];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = qualification2.Id;
        contentDocumentLink.ShareType = 'I';
        contentDocumentLink.Visibility = 'InternalUsers';
        insert contentDocumentLink;

        ComplianceQualificationsController.getQualifications(candidate2.Id, new List<String>{'General'});
    }
    
}