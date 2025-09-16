@isTest
public with sharing class PayQueriesListViewControllerTest {
    @isTest
    static void getPayQueries_givenContactId_returnsCorrectPayQueries() {
        Contact contact1 = new Contact(FirstName = 'Bob', LastName = 'Bobbins');
        Contact contact2 = new Contact(FirstName = 'Bobbery', LastName = 'Dobbery');
        insert new List<SObject>{ contact1, contact2 };

        Pay_Query__c payQuery1 = new Pay_Query__c(
            Type__c = 'Missing Hours',
            Description_of_your_Query__c = 'Please help me 1',
            Person__c = contact1.Id,
            Status__c = 'Open',
            Payslip_Date__c = Date.today().addDays(-1)
        );

        Pay_Query__c payQuery2 = new Pay_Query__c(
            Type__c = 'Missing Hours',
            Description_of_your_Query__c = 'Please help me 2',
            Person__c = contact2.Id,
            Status__c = 'Open',
            Payslip_Date__c = Date.today().addDays(-8)
        );

        Pay_Query__c payQuery3 = new Pay_Query__c(
            Type__c = 'Missing Hours',
            Description_of_your_Query__c = 'Please help me 3',
            Person__c = contact1.Id,
            Status__c = 'Open',
            Payslip_Date__c = Date.today().addDays(-1)
        );

        insert new List<SObject>{ payQuery1, payQuery2, payQuery3 };

        Test.startTest();
        List<PayQueriesListViewController.PayQuery> payQueries = PayQueriesListViewController.getPayQueries(
            contact1.Id
        );
        Test.stopTest();

        System.assertEquals(2, payQueries.size(), 'Should have correct number of pay queries');

        {
            PayQueriesListViewController.PayQuery payQuery = payQueries.get(0);
            System.assertEquals(payQuery1.Id, payQuery.id, 'Should have correct id');
            System.assertEquals('Please help me 1', payQuery.description, 'Should have correct description');
        }

        {
            PayQueriesListViewController.PayQuery payQuery = payQueries.get(1);
            System.assertEquals(payQuery3.Id, payQuery.id, 'Should have correct id');
            System.assertEquals('Please help me 3', payQuery.description, 'Should have correct description');
        }
    }
}