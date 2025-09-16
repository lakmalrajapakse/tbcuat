@isTest
public with sharing class ComplianceAddQualificationControllerTest {
    @isTest
    static void getCompetencies_returnsCorrectData() {
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

        List<ComplianceAddQualificationController.Competency> results = ComplianceAddQualificationController.getCompetencies(
            new List<String>{ 'General' }
        );

        System.assertEquals(1, results.size(), 'Should return correct number of competencies');

        {
            ComplianceAddQualificationController.Competency result = results.get(0);
            System.assertEquals('Test Competency 1', result.name, 'Should be correct name');
            System.assertEquals('General', result.category, 'Should be correct category');
            System.assertEquals(true, result.requiresProof, 'Should be correct proof value');
            System.assertEquals(false, result.canExpire, 'Should be correct expires value');
        }
    }

    @isTest
    static void addQualification_insertsCorrectData() {
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

        ComplianceAddQualificationController.Qualification subject = new ComplianceAddQualificationController.Qualification();
        subject.contactId = candidate1.Id;
        subject.competencyId = competency1.Id;
        subject.validFrom = Date.newInstance(2025, 8, 1);
        subject.validTo = Date.newInstance(2025, 10, 1);
        subject.attachmentIds = new List<Id>();

        ComplianceAddQualificationController.addQualification(subject);

        List<sirenum__Ticket__c> results = [
            SELECT sirenum__TicketType__c, sirenum__Owner__c, sirenum__Valid_from__c, sirenum__Valid_until__c
            FROM sirenum__Ticket__c
        ];

        System.assertEquals(1, results.size(), 'Should return correct number of qualifications');

        {
            sirenum__Ticket__c qual = results.get(0);
            System.assertEquals(competency1.Id, qual.sirenum__TicketType__c, 'Should be correct competency');
            System.assertEquals(candidate1.Id, qual.sirenum__Owner__c, 'Should be correct candidate');
            System.assertEquals(Date.newInstance(2025, 8, 1), qual.sirenum__Valid_from__c, 'Should be valid from');
            System.assertEquals(Date.newInstance(2025, 10, 1), qual.sirenum__Valid_until__c, 'Should be valid until');
        }
    }
}