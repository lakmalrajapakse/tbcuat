@isTest
public with sharing class ObjectSearchGridControllerTest {
    @isTest
    static void search_findsCorretRecords() {
        Contact candidate1 = new Contact(FirstName = 'Bob', LastName = 'Dobbery');
        Contact candidate2 = new Contact(FirstName = 'Bill', LastName = 'Jones');
        insert new List<SObject>{ candidate1, candidate2 };

        List<Contact> results = ObjectSearchGridController.search('Bob', 'Contact', new List<String>{ 'Name' });
    }
}