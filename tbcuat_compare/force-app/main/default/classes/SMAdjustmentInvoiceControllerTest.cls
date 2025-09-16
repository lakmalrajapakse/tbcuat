@isTest
public with sharing class SMAdjustmentInvoiceControllerTest {
    @isTest
    static void getInvoiceEntries_givenTimesheetIds_returnsUniqueInvoiceNumbers() {
        // GIVEN
        Contact worker = new Contact(
            FirstName = 'Joe',
            LastName = 'Bloggs',
            Do_you_have_the_right_to_work_in_the_UK__c = true,
            Do_you_currently_live_in_the_UK__c = true
        );
        insert worker;

        sirenum__Payroll_Cycle__c cycle = new sirenum__Payroll_Cycle__c(
            sirenum__periodLength__c = 7,
            sirenum__StartingDate__c = Date.newInstance(2022, 1, 1),
            sirenum__CyclePeriodUnits__c = 'Weeks',
            Name = 'Test Cycle'
        );

        insert cycle;

        sirenum__Week__c period = new sirenum__Week__c(
            sirenum__PayrollCycle__c = cycle.Id,
            sirenum__Start_Date__c = Date.newInstance(2022, 1, 1),
            sirenum__Week_Ending__c = Date.newInstance(2022, 1, 7),
            Name = 'Test Period'
        );

        insert period;

        sirenum__Team__c jobRole1 = new sirenum__Team__c(Name = 'Job Role 1');

        insert new List<SObject>{ jobRole1 };

        sirenum__Shift__c shift1 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 15, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 16, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );

        insert new List<SObject>{ shift1 };

        sirenum__Timesheet__c timesheet1 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-1',
            sirenum__Team__c = jobRole1.Id,
            InTime_Invoice_No__c = 'Invoice 1'
        );
        insert new List<SObject>{ timesheet1 };

        sirenum__Timesheet_Line__c timesheetLine1 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet1.Id,
            sirenum__Hours__c = 10,
            sirenum__Rate__c = 100.0,
            sirenum__Charge__c = 5,
            sirenum__Shift__c = shift1.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 3)
        );

        insert new List<SObject>{ timesheetLine1 };

        // WHEN
        SMAdjustmentInvoiceController.GetInvoiceEntriesRequest request = new SMAdjustmentInvoiceController.GetInvoiceEntriesRequest();
        request.timesheetIds = new List<Id>{ timesheet1.Id };

        Test.startTest();
        SMAdjustmentInvoiceController.GetInvoiceEntriesResponse response = (SMAdjustmentInvoiceController.GetInvoiceEntriesResponse) JSON.deserialize(
            SMAdjustmentInvoiceController.getInvoiceEntries(JSON.serialize(request)),
            SMAdjustmentInvoiceController.GetInvoiceEntriesResponse.class
        );
        Test.stopTest();

        // THEN
        Assert.areEqual(1, response.invoiceEntries.size(), 'Response should have the correct number of invoic entries');
        Assert.areEqual('Invoice 1', response.invoiceEntries.get(0), 'Should be correct invoice entry');
    }
}