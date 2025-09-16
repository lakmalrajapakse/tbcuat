@isTest
public with sharing class ComplianceAddRatingsControllerTest {
    @isTest
    static void getRatingOptions_returnsCorrectData() {
        List<ComplianceAddRatingController.RatingOption> results = ComplianceAddRatingController.getRatingOptions();

        System.assertEquals(5, results.size(), 'Should return correct number of picklist values');

        {
            ComplianceAddRatingController.RatingOption option = results.get(0);
            System.assertEquals('Excellent', option.label, 'Should be correct label');
            System.assertEquals('Excellent', option.value, 'Should be correct value');
        }
    }

    @isTest
    static void addRating_insertsCorrectData() {
        Contact candidate1 = new Contact(FirstName = 'Bob', LastName = 'Dobbery');
        Contact candidate2 = new Contact(FirstName = 'Bob', LastName = 'Dobbery');
        insert new List<SObject>{ candidate1, candidate2 };

        Account customer1 = new Account(Name='Customer 1');

        insert new List<SObject>{ customer1 };

        ComplianceAddRatingController.Rating subject = new ComplianceAddRatingController.Rating();
        subject.contactId = candidate1.Id;
        subject.raterId = candidate2.Id;
        subject.customerId = customer1.Id;
        subject.rating = 'Excellent';
        
        ComplianceAddRatingController.addRating(subject);

        List<sirenum__Ranking__c> results = [SELECT sirenum__Contact__c,
        sirenum__Rank__c,
        sirenum__Ranked_by__c,
        sirenum__Account__c FROM  sirenum__Ranking__c];

        System.assertEquals(1, results.size(), 'Should return correct number of ratings');

        {
            sirenum__Ranking__c rating = results.get(0);
            System.assertEquals(candidate2.Id, rating.sirenum__Ranked_by__c, 'Should be correct ranked by');
            System.assertEquals(candidate1.Id, rating.sirenum__Contact__c, 'Should be correct candidate');
            System.assertEquals(customer1.Id, rating.sirenum__Account__c, 'Should be correct customer');
            System.assertEquals('Excellent', rating.sirenum__Rank__c, 'Should be correct rating');
        }
    }
}