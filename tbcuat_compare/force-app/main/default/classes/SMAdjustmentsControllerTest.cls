@isTest
public with sharing class SMAdjustmentsControllerTest {
    @isTest
    static void getTimesheets_whenTimesheetStartDateIsWithinRange_returnsCorrectTimesheetsAndSummaries() {
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

        sirenum__Team__c jobRole2 = new sirenum__Team__c(Name = 'Job Role 2');

        insert new List<SObject>{ jobRole1, jobRole2 };

        sirenum__Shift__c shift1 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 15, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 16, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );
        sirenum__Shift__c shift2 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 18, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 19, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );

        insert new List<SObject>{ shift1, shift2 };

        sirenum__Timesheet__c timesheet1 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-1',
            sirenum__Team__c = jobRole1.Id,
            InTimeId__c = 'Test-1'
        );

        sirenum__Timesheet__c timesheet2 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-2',
            sirenum__Team__c = jobRole2.Id,
            InTimeId__c = 'Test-1'
        );

        TriggerHandler.bypass('TimesheetTriggerHandler');
        insert new List<SObject>{ timesheet1, timesheet2 };

        sirenum__Timesheet_Line__c timesheetLine1 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet1.Id,
            sirenum__Hours__c = 10,
            sirenum__Rate__c = 100.0,
            sirenum__Charge__c = 5,
            sirenum__Shift__c = shift1.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 3)
        );

        sirenum__Timesheet_Line__c timesheetLine2 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet2.Id,
            sirenum__Hours__c = 11,
            sirenum__Rate__c = 101.0,
            sirenum__Charge__c = 8,
            sirenum__Shift__c = shift2.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 2)
        );

        insert new List<SObject>{ timesheetLine1, timesheetLine2 };

        // WHEN
        SMAdjustmentsController.GetTimesheetsRequest request = new SMAdjustmentsController.GetTimesheetsRequest();
        request.weekStart = Date.newInstance(2022, 1, 1).format();
        request.weekEnd = Date.newInstance(2022, 1, 7).format();

        Test.startTest();
        SMAdjustmentsController.GetTimesheetsResponse response = (SMAdjustmentsController.GetTimesheetsResponse) JSON.deserialize(
            SMAdjustmentsController.getTimesheets(JSON.serialize(request)),
            SMAdjustmentsController.GetTimesheetsResponse.class
        );
        Test.stopTest();

        // THEN
        System.Assert.areEqual(2, response.Summaries.size(), 'Response should have the correct number of summaries');

        {
            sirenum__Timesheet__c timesheet = [
                SELECT
                    Id,
                    Name,
                    sirenum__Total_Pay__c,
                    sirenum__Total_Charge__c,
                    sirenum__Worker__r.Name,
                    sirenum__PO_Number__c,
                    sirenum__Team__r.Name
                FROM sirenum__Timesheet__c
                WHERE Id = :timesheet1.Id
            ];

            sirenum__Timesheet_Line__c timesheetLine = [
                SELECT
                    Id,
                    Name,
                    sirenum__Total_Pay__c,
                    sirenum__Total_Charge__c,
                    sirenum__Shift__c,
                    sirenum__Timesheet__c
                FROM sirenum__Timesheet_Line__c
                WHERE Id = :timesheetLine1.Id
            ];

            SMAdjustmentsController.TimesheetSummary summary = response.Summaries.get(0);

            Assert.areEqual(timesheet.Id, summary.Id, 'Summary should have correct id');
            Assert.areEqual(timesheet.Name, summary.Name, 'Summary should have correct name');
            Assert.areEqual(1000, summary.Pay, 'Summary should have correct pay');
            Assert.areEqual(50, summary.Charge, 'Summary should have correct charge');
            Assert.areEqual('Joe Bloggs', summary.WorkerName, 'Summary should have correct worker name');
            Assert.areEqual('Test-PO-1', summary.PONumber, 'Summary should have correct po number');
            Assert.areEqual('Job Role 1', summary.JobRole, 'Summary should have correct job role');
        }

        {
            sirenum__Timesheet__c timesheet = [
                SELECT
                    Id,
                    Name,
                    sirenum__Total_Pay__c,
                    sirenum__Total_Charge__c,
                    sirenum__Worker__r.Name,
                    sirenum__PO_Number__c,
                    sirenum__Team__r.Name
                FROM sirenum__Timesheet__c
                WHERE Id = :timesheet2.Id
            ];

            sirenum__Timesheet_Line__c timesheetLine = [
                SELECT
                    Id,
                    Name,
                    sirenum__Total_Pay__c,
                    sirenum__Total_Charge__c,
                    sirenum__Shift__c,
                    sirenum__Timesheet__c
                FROM sirenum__Timesheet_Line__c
                WHERE Id = :timesheetLine2.Id
            ];

            SMAdjustmentsController.TimesheetSummary summary = response.Summaries.get(1);

            Assert.areEqual(timesheet.Id, summary.Id, 'Summary should have correct id');
            Assert.areEqual(timesheet.Name, summary.Name, 'Summary should have correct name');
            Assert.areEqual(1111, summary.Pay, 'Summary should have correct pay');
            Assert.areEqual(88, summary.Charge, 'Summary should have correct charge');
            Assert.areEqual('Joe Bloggs', summary.WorkerName, 'Summary should have correct worker name');
            Assert.areEqual('Test-PO-2', summary.PONumber, 'Summary should have correct po number');
            Assert.areEqual('Job Role 2', summary.JobRole, 'Summary should have correct job role');
        }
    }

    @isTest
    static void adjust_willCallAdjustmentService() {
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

        sirenum__Team__c jobRole2 = new sirenum__Team__c(Name = 'Job Role 2');

        insert new List<SObject>{ jobRole1, jobRole2 };

        sirenum__Shift__c shift1 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 15, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 16, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );
        sirenum__Shift__c shift2 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 18, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 19, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );

        insert new List<SObject>{ shift1, shift2 };

        sirenum__Timesheet__c timesheet1 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-1',
            sirenum__Team__c = jobRole1.Id
        );

        sirenum__Timesheet__c timesheet2 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-2',
            sirenum__Team__c = jobRole2.Id
        );
        insert new List<SObject>{ timesheet1, timesheet2 };

        sirenum__Timesheet_Line__c timesheetLine1 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet1.Id,
            sirenum__Hours__c = 10,
            sirenum__Rate__c = 100.0,
            sirenum__Charge__c = 5,
            sirenum__Shift__c = shift1.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 3)
        );

        sirenum__Timesheet_Line__c timesheetLine2 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet2.Id,
            sirenum__Hours__c = 11,
            sirenum__Rate__c = 101.0,
            sirenum__Charge__c = 8,
            sirenum__Shift__c = shift2.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 2)
        );

        insert new List<SObject>{ timesheetLine1, timesheetLine2 };

        // WHEN
        List<TimesheetAdjustmentService.AdjustmentRequest> request = new List<TimesheetAdjustmentService.AdjustmentRequest>{
            new TimesheetAdjustmentService.AdjustmentRequest()
        };

        Test.startTest();
        SMAdjustmentsController.adjust(JSON.serialize(request));
        Test.stopTest();
    }

    @isTest
    static void reverse_willCallAdjustmentService() {
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

        sirenum__Team__c jobRole2 = new sirenum__Team__c(Name = 'Job Role 2');

        insert new List<SObject>{ jobRole1, jobRole2 };

        sirenum__Shift__c shift1 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 15, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 16, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );
        sirenum__Shift__c shift2 = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(2022, 1, 5, 18, 30, 0),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(2025, 1, 5, 19, 30, 0),
            sirenum__Cancelled__c = false,
            sirenum__Contact__c = worker.Id
        );

        insert new List<SObject>{ shift1, shift2 };

        sirenum__Timesheet__c timesheet1 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-1',
            sirenum__Team__c = jobRole1.Id
        );

        sirenum__Timesheet__c timesheet2 = new sirenum__Timesheet__c(
            sirenum__Worker__c = worker.Id,
            sirenum__Week__c = period.Id,
            sirenum__PO_Number__c = 'Test-PO-2',
            sirenum__Team__c = jobRole2.Id
        );
        insert new List<SObject>{ timesheet1, timesheet2 };

        sirenum__Timesheet_Line__c timesheetLine1 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet1.Id,
            sirenum__Hours__c = 10,
            sirenum__Rate__c = 100.0,
            sirenum__Charge__c = 5,
            sirenum__Shift__c = shift1.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 3)
        );

        sirenum__Timesheet_Line__c timesheetLine2 = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheet2.Id,
            sirenum__Hours__c = 11,
            sirenum__Rate__c = 101.0,
            sirenum__Charge__c = 8,
            sirenum__Shift__c = shift2.Id,
            sirenum__Date__c = Date.newInstance(2022, 1, 2)
        );

        insert new List<SObject>{ timesheetLine1, timesheetLine2 };

        // WHEN
        List<TimesheetAdjustmentService.AdjustmentRequest> request = new List<TimesheetAdjustmentService.AdjustmentRequest>{
            new TimesheetAdjustmentService.AdjustmentRequest()
        };

        Test.startTest();
        SMAdjustmentsController.reverse(JSON.serialize(request));
        Test.stopTest();
    }
}