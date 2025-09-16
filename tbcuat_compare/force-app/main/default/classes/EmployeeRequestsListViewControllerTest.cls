@isTest
public with sharing class EmployeeRequestsListViewControllerTest {
    @isTest
    static void getEmployeeRequests_givenContactId_returnsCorrectEmployeeRequests() {
        Contact contact1 = new Contact(FirstName = 'Bob', LastName = 'Bobbins');
        Contact contact2 = new Contact(FirstName = 'Bobbery', LastName = 'Dobbery');
        insert new List<SObject>{ contact1, contact2 };

        Date startDate = Date.newInstance(2025, 02, 13);
        Date endDate = Date.newInstance(2025, 02, 14);

        sirenum__Employee_Request__c employeeRequest1 = new sirenum__Employee_Request__c(
            sirenum__Type__c = 'Holiday',
            sirenum__Contact__c = contact1.Id,
            sirenum__Start_Time__c = startDate,
            sirenum__End_Time__c = endDate,
            sirenum__Approved__c = false,
            sirenum__Rejected__c = true
        );

        sirenum__Employee_Request__c employeeRequest2 = new sirenum__Employee_Request__c(
            sirenum__Type__c = 'Absent Leave',
            sirenum__Contact__c = contact2.Id,
            sirenum__Start_Time__c = startDate,
            sirenum__End_Time__c = endDate,
            sirenum__Approved__c = false,
            sirenum__Rejected__c = false
        );

        sirenum__Employee_Request__c employeeRequest3 = new sirenum__Employee_Request__c(
            sirenum__Type__c = 'Sick Leave',
            sirenum__Contact__c = contact1.Id,
            sirenum__Start_Time__c = startDate,
            sirenum__End_Time__c = endDate,
            sirenum__Approved__c = true,
            sirenum__Rejected__c = false
        );

        insert new List<SObject>{ employeeRequest1, employeeRequest2, employeeRequest3 };

        Test.startTest();
        List<EmployeeRequestsListViewController.EmployeeRequest> employeeRequests = EmployeeRequestsListViewController.getEmployeeRequests(
            contact1.Id
        );
        Test.stopTest();

        System.assertEquals(2, employeeRequests.size(), 'Should have correct number of employee requests');

        {
            EmployeeRequestsListViewController.EmployeeRequest payQuery = employeeRequests.get(0);
            System.assertEquals(employeeRequest1.Id, payQuery.id, 'Should have correct id');
            System.assertEquals('Holiday', payQuery.type, 'Should have correct type');
            System.AssertEquals(startDate, payQuery.startDate, 'Should have correct startDate');
            System.AssertEquals(endDate, payQuery.endDate, 'Should have correct endDate');
            System.AssertEquals(false, payQuery.approved, 'Should have correct approved');
            System.AssertEquals(true, payQuery.rejected, 'Should have correct rejected');
        }

        {
            EmployeeRequestsListViewController.EmployeeRequest payQuery = employeeRequests.get(1);
            System.assertEquals(employeeRequest3.Id, payQuery.id, 'Should have correct id');
            System.assertEquals('Sick Leave', payQuery.type, 'Should have correct type');
            System.AssertEquals(startDate, payQuery.startDate, 'Should have correct startDate');
            System.AssertEquals(endDate, payQuery.endDate, 'Should have correct endDate');
            System.AssertEquals(true, payQuery.approved, 'Should have correct approved');
            System.AssertEquals(false, payQuery.rejected, 'Should have correct rejected');
        }
    }
}