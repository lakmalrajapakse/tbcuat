@isTest
public with sharing class ComplianceRatingsControllerTest {
    @isTest
    static void getRatings_returnsCorrectData() {
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

        insert rating1;

        ComplianceRatingsController.getRatings(candidate1.Id);
    }
}