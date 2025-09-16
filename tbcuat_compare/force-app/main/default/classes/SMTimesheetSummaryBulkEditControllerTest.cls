@isTest
private class SMTimesheetSummaryBulkEditControllerTest {
    @IsTest
    static void updateTimesheets_givenValidBulkEditDto_performsUpdateToGivenRecords() {
        // GIVEN
        Contact worker = new Contact(FirstName = 'Joe', LastName = 'Bloggs');
        insert worker;

        sirenum__Timesheet__c firstTimesheet = new sirenum__Timesheet__c(
            sirenum__PO_Number__c = 'Old-PO-123',
            sirenum__Worker__c = worker.Id
        );
        insert firstTimesheet;

        sirenum__Timesheet__c secondTimesheet = new sirenum__Timesheet__c(
            sirenum__PO_Number__c = 'Old-PO-123',
            sirenum__Worker__c = worker.Id
        );
        insert secondTimesheet;

        SMTimesheetSummaryBulkEditController.TimesheetSummaryBulkEditDto bulkEditData = new SMTimesheetSummaryBulkEditController.TimesheetSummaryBulkEditDto();
        bulkEditData.recordIds = new List<Id>{ firstTimesheet.Id, secondTimesheet.Id };
        bulkEditData.poNumber = 'New-PO-456';

        String bulkEditJson = JSON.serialize(bulkEditData);

        // WHEN
        Test.startTest();
        SMTimesheetSummaryBulkEditController.updateTimesheets(bulkEditJson);
        Test.stopTest();

        // THEN
        List<sirenum__Timesheet__c> updatedTimesheets = [
            SELECT Id, sirenum__PO_Number__c
            FROM sirenum__Timesheet__c
        ];

        Assert.areEqual(2, updatedTimesheets.size(), 'Should have found 2 timesheets');
        Assert.areEqual(
            'New-PO-456',
            updatedTimesheets.get(0).sirenum__PO_Number__c,
            'PO Number should have been updated'
        );
        Assert.areEqual(
            'New-PO-456',
            updatedTimesheets.get(1).sirenum__PO_Number__c,
            'PO Number should have been updated'
        );
    }

    @IsTest
    static void updateTimesheets_givenTimesheetWithPoNumberThatExceedsLimit_throwsAuraHandledExceptionAndCommitsNothing() {
        // GIVEN
        Contact worker = new Contact(FirstName = 'Joe', LastName = 'Bloggs');
        insert worker;

        sirenum__Timesheet__c firstTimesheet = new sirenum__Timesheet__c(
            sirenum__PO_Number__c = 'Old-PO-123',
            sirenum__Worker__c = worker.Id
        );
        insert firstTimesheet;

        SMTimesheetSummaryBulkEditController.TimesheetSummaryBulkEditDto bulkEditData = new SMTimesheetSummaryBulkEditController.TimesheetSummaryBulkEditDto();
        bulkEditData.recordIds = new List<Id>{ firstTimesheet.Id };
        bulkEditData.poNumber = 'This is a very long po number that exceeds the limit';

        String bulkEditJson = JSON.serialize(bulkEditData);

        String exType = '';

        // WHEN
        try {
            Test.startTest();
            SMTimesheetSummaryBulkEditController.updateTimesheets(bulkEditJson);
            Test.stopTest();
            Assert.fail('Shouldve thrown an AuraHandledException');
        } catch (Exception ex) {
            exType = ex.getTypeName();
        }

        // THEN
        Assert.areEqual('System.AuraHandledException', exType, 'Method shouldve thrown an AuraHandledException');

        List<sirenum__Timesheet__c> updatedTimesheets = [
            SELECT Id, sirenum__PO_Number__c
            FROM sirenum__Timesheet__c
        ];

        Assert.areEqual(1, updatedTimesheets.size(), 'Should have found 1 timesheet');
        Assert.areEqual(
            'Old-PO-123',
            updatedTimesheets.get(0).sirenum__PO_Number__c,
            'PO Number should not have been updated'
        );
    }

    @IsTest
    static void updateTimesheets_givenInvalidBulkEditDto_throwsAuraHandledExceptionAndCommitsNothing() {
        // GIVEN
        Contact worker = new Contact(FirstName = 'Joe', LastName = 'Bloggs');
        insert worker;

        sirenum__Timesheet__c firstTimesheet = new sirenum__Timesheet__c(
            sirenum__PO_Number__c = 'Old-PO-123',
            sirenum__Worker__c = worker.Id
        );
        insert firstTimesheet;

        String bulkEditJson = JSON.serialize('this isnt going to deserialise into TimesheetSummaryBulkEditDto');

        String exType = '';

        // WHEN
        try {
            Test.startTest();
            SMTimesheetSummaryBulkEditController.updateTimesheets(bulkEditJson);
            Test.stopTest();
            Assert.fail('Shouldve thrown an AuraHandledException');
        } catch (Exception ex) {
            exType = ex.getTypeName();
        }

        // THEN
        Assert.areEqual('System.AuraHandledException', exType, 'Method shouldve thrown an AuraHandledException');

        List<sirenum__Timesheet__c> updatedTimesheets = [
            SELECT Id, sirenum__PO_Number__c
            FROM sirenum__Timesheet__c
        ];

        Assert.areEqual(1, updatedTimesheets.size(), 'Should have found 1 timesheet');
        Assert.areEqual(
            'Old-PO-123',
            updatedTimesheets.get(0).sirenum__PO_Number__c,
            'PO Number should not have been updated'
        );
    }
}