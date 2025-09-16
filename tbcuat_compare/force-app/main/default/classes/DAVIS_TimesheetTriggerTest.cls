@isTest
public class DAVIS_TimesheetTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a Contact with DVLA_License_Check__c = false
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Driver',
            DVLA_License_Check__c = false
        );
        insert c;

        // Create a Sirenum__Team__c with Job_Role_is_Driver__c = true
        Sirenum__Team__c team = new Sirenum__Team__c(

            Job_Role_is_Driver__c = true
        );
        insert team;

        // Create a timesheet with status not yet Approved (for update test later)
        Sirenum__Timesheet__c ts = new Sirenum__Timesheet__c(
            Status__c = 'Submitted',
            Sirenum__Worker__c = c.Id,
            Sirenum__Team__c = team.Id
        );
        insert ts;
    }

    @isTest
    static void testUpdateToApprovedStatus() {
        Contact c = [SELECT Id, DVLA_License_Check__c FROM Contact LIMIT 1];
        Sirenum__Timesheet__c ts = [SELECT Id, Status__c FROM Sirenum__Timesheet__c WHERE Status__c = 'Submitted' LIMIT 1];

        ts.Status__c = 'Approved';
        update ts;

        Contact updatedContact = [SELECT DVLA_License_Check__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, updatedContact.DVLA_License_Check__c, 'DVLA_License_Check__c should be set to true after updating status to Approved.');
    }

    @isTest
    static void testNonDriverTeam() {
        // Create new contact
        Contact c = new Contact(
            FirstName = 'Non',
            LastName = 'Driver',
            DVLA_License_Check__c = false
        );
        insert c;

        // Create team with Job_Role_is_Driver__c = false
        Sirenum__Team__c team = new Sirenum__Team__c(
            Name = 'Non-Driver Team',
            Job_Role_is_Driver__c = false
        );
        insert team;

        // Create approved timesheet, but team is not driver
        Sirenum__Timesheet__c ts = new Sirenum__Timesheet__c(
            Status__c = 'Approved',
            Sirenum__Worker__c = c.Id,
            Sirenum__Team__c = team.Id
        );
        insert ts;

        Contact updatedContact = [SELECT DVLA_License_Check__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(false, updatedContact.DVLA_License_Check__c, 'DVLA_License_Check__c should remain false if team is not driver.');
    }

    @isTest
    static void testAlreadyCheckedContact() {
        // Create contact that already has DVLA_License_Check__c = true
        Contact c = new Contact(
            FirstName = 'Already',
            LastName = 'Checked',
            DVLA_License_Check__c = true
        );
        insert c;

        // Use existing team with driver role
        Sirenum__Team__c team = [SELECT Id FROM Sirenum__Team__c WHERE Job_Role_is_Driver__c = true LIMIT 1];

        // Create approved timesheet
        Sirenum__Timesheet__c ts = new Sirenum__Timesheet__c(
            Status__c = 'Approved',
            Sirenum__Worker__c = c.Id,
            Sirenum__Team__c = team.Id
        );
        insert ts;

        Contact updatedContact = [SELECT DVLA_License_Check__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, updatedContact.DVLA_License_Check__c, 'Already true value should remain unchanged.');
    }
}