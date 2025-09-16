@isTest
public with sharing class JobOffersControllerTest {
    @isTest
    static void getJobOffers_givenContactId_returnsCorrectJobOffers()
    {
        DateTime startTime = DateTime.newInstance(2025, 1, 31, 18, 30, 0);
        DateTime endTime = DateTime.newInstance(2025, 1, 31, 23, 30, 0);

        Contact contact = new Contact(FirstName = 'Bob', LastName = 'Bobbins');
        insert contact;

        sirenum__Site__c site = new sirenum__Site__c(Name = 'McDonalds');
        insert site;

        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = startTime,
            sirenum__Scheduled_End_Time__c = endTime,
            sirenum__Site__c = site.Id
        );

        insert shift;

        sirenum__Shift_Invitation__c shiftInvitation = new sirenum__Shift_Invitation__c(
            sirenum__Shift__c = shift.Id,
            sirenum__Status__c = 'Broadcasting',
            sirenum__Contact__c = contact.Id
        );

        insert shiftInvitation;

        Test.startTest();
        List<JobOffersController.JobOffer> offers = JobOffersController.getJobOffers(contact.Id);
        Test.stopTest();

        System.assertEquals(1, offers.size(), 'Should have correct number of offers');
        {
            JobOffersController.JobOffer offer = offers.get(0);
            System.assertEquals(shiftInvitation.Id, offer.id, 'Should have correct id');
            System.assertEquals('McDonalds', offer.name, 'Should have correct name');
            System.assertEquals(startTime, offer.startTime, 'Should have correct start time');
            System.assertEquals(endTime, offer.endTime, 'Should have correct end time');
        }
    }

    @isTest
    static void decline_givenOfferId_setsCorrecStatus()
    {
        DateTime startTime = DateTime.newInstance(2025, 1, 31, 18, 30, 0);
        DateTime endTime = DateTime.newInstance(2025, 1, 31, 23, 30, 0);

        Contact contact = new Contact(FirstName = 'Bob', LastName = 'Bobbins');
        insert contact;

        sirenum__Site__c site = new sirenum__Site__c(Name = 'McDonalds');
        insert site;

        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = startTime,
            sirenum__Scheduled_End_Time__c = endTime,
            sirenum__Site__c = site.Id
        );

        insert shift;

        sirenum__Shift_Invitation__c shiftInvitation = new sirenum__Shift_Invitation__c(
            sirenum__Shift__c = shift.Id,
            sirenum__Status__c = 'Broadcasting',
            sirenum__Contact__c = contact.Id
        );

        insert shiftInvitation;

        Test.startTest();
        JobOffersController.decline(shiftInvitation.Id);
        Test.stopTest();

        shiftInvitation = [SELECT Id, sirenum__Status__c FROM sirenum__Shift_Invitation__c WHERE Id = :shiftInvitation.Id];

        System.assertEquals('Declined', shiftInvitation.sirenum__Status__c, 'Status should have been updated correctly');
    }
    

    @isTest
    static void accept_givenOfferId_setsCorrecStatus()
    {
        DateTime startTime = DateTime.newInstance(2025, 1, 31, 18, 30, 0);
        DateTime endTime = DateTime.newInstance(2025, 1, 31, 23, 30, 0);

        Contact contact = new Contact(FirstName = 'Bob', LastName = 'Bobbins');
        insert contact;

        sirenum__Site__c site = new sirenum__Site__c(Name = 'McDonalds');
        insert site;

        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = startTime,
            sirenum__Scheduled_End_Time__c = endTime,
            sirenum__Site__c = site.Id
        );

        insert shift;

        sirenum__Shift_Invitation__c shiftInvitation = new sirenum__Shift_Invitation__c(
            sirenum__Shift__c = shift.Id,
            sirenum__Status__c = 'Broadcasting',
            sirenum__Contact__c = contact.Id
        );

        insert shiftInvitation;

        Test.startTest();
        JobOffersController.accept(shiftInvitation.Id);
        Test.stopTest();

        shiftInvitation = [SELECT Id, sirenum__Status__c FROM sirenum__Shift_Invitation__c WHERE Id = :shiftInvitation.Id];

        System.assertEquals('Accepted', shiftInvitation.sirenum__Status__c, 'Status should have been updated correctly');
    }
}