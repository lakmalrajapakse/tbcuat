@isTest
public with sharing class ComplianceServiceTest {
    @isTest
    static void getCompetencies_returnsCorrectRecords() {
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

        List<sirenum__TicketType__c> results = ComplianceService.getCompetencies(new List<String>{ 'General' });

        System.assertEquals(1, results.size(), 'Should return correct number of competencies');

        {
            sirenum__TicketType__c result = results.get(0);
            System.assertEquals('Test Competency 1', result.Name, 'Should be correct name');
            System.assertEquals('General', result.Competency_Category__c, 'Should be correct category');
            System.assertEquals(true, result.sirenum__Requires_Proof__c, 'Should be correct proof value');
            System.assertEquals(false, result.sirenum__Expires__c, 'Should be correct expires value');
        }
    }

    @isTest
    static void getQualifications_returnsCorrectRecords() {
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

        List<sirenum__Ticket__c> results = ComplianceService.getQualifications(
            candidate2.Id,
            new List<String>{ 'General' }
        );

        System.assertEquals(1, results.size(), 'Should return correct number of qualifications');

        {
            sirenum__Ticket__c result = results.get(0);
            System.assertEquals('Test Competency 1', result.sirenum__TicketType__r.Name, 'Should be correct type of qualification');
            System.assertEquals(Date.newInstance(2025, 5, 1), result.sirenum__Valid_from__c, 'Should be correct proof value');
            System.assertEquals(Date.newInstance(2025, 6, 1), result.sirenum__Valid_until__c, 'Should be correct expires value');
        }
    }

    @isTest
    static void getRatings_returnsCorrectRecords() {
        Contact candidate1 = new Contact(FirstName = 'Bob', LastName = 'Dobbery');
        Contact candidate2 = new Contact(FirstName = 'Bill', LastName = 'Jones');
        insert new List<SObject>{ candidate1, candidate2 };

        Account customer1 = new Account(Name='Customer 1');
        Account customer2 = new Account(Name='Customer 2');

        insert new List<SObject>{ customer1, customer2 };

        sirenum__Ranking__c rating1 = new sirenum__Ranking__c(
            sirenum__Contact__c = candidate1.Id,
            sirenum__Rank__c = 'Good',
            sirenum__Ranked_by__c = candidate2.id,
            sirenum__Account__c = customer1.Id
        );

        sirenum__Ranking__c rating2 = new sirenum__Ranking__c(
            sirenum__Contact__c = candidate2.Id,
            sirenum__Rank__c = 'Poor',
            sirenum__Ranked_by__c = candidate1.id,
            sirenum__Account__c = customer2.Id
        );

        insert new List<SObject>{ rating1, rating2 };

        List<sirenum__Ranking__c> results = ComplianceService.getRatings(
            candidate1.Id
        );

        System.assertEquals(1, results.size(), 'Should return correct number of ratings');

        {
            sirenum__Ranking__c result = results.get(0);
            System.assertEquals(candidate1.Id, result.sirenum__Contact__c, 'Should be correct contact');
            System.assertEquals('Good', result.sirenum__Rank__c, 'Should be correct rank');
        }
    }

    @isTest
    static void getQualificationAttachments_returnsCorrectRecords() {
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

        List<ContentDocumentLink> results = ComplianceService.getQualificationAttachments(
           new Set<Id>{qualification2.Id}
        );

        System.assertEquals(1, results.size(), 'Should return correct number of attachments');

        {
            ContentDocumentLink result = results.get(0);
            System.assertEquals(qualification2.Id, result.LinkedEntityId, 'Should be correct linked entity');
        }
    }
}