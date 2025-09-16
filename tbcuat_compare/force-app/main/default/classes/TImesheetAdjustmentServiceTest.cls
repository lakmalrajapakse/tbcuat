@isTest
public with sharing class TImesheetAdjustmentServiceTest {
    @isTest
    static void adjust_givenAdjustmentsToPayRate_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.lines = new List<TimesheetAdjustmentService.AdjustmentTimesheetLine>();

        TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine1 = new TimesheetAdjustmentService.AdjustmentTimesheetLine();
        adjustmentLine1.timesheetLineId = scenario.timesheet1Line1.Id;
        adjustmentLine1.payRate = 55;

        request.timesheet.lines.add(adjustmentLine1);

        Test.startTest();
        TimesheetAdjustmentService.adjust(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment Pay Only', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            scenario.timesheet1.Id,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(1, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        {
            sirenum__Timesheet__c record = scenario.adjustmentTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Adjustment', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(55, lineRecord.sirenum__Rate__c, 'Rate should have been updated');
            }
        }

        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of reversal lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );
                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    @isTest
    static void adjust_givenAdjustmentsToChargeRate_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.lines = new List<TimesheetAdjustmentService.AdjustmentTimesheetLine>();

        TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine1 = new TimesheetAdjustmentService.AdjustmentTimesheetLine();
        adjustmentLine1.timesheetLineId = scenario.timesheet1Line1.Id;
        adjustmentLine1.chargeRate = 55;

        request.timesheet.lines.add(adjustmentLine1);

        Test.startTest();
        TimesheetAdjustmentService.adjust(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment Charge Only', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            scenario.timesheet1.Id,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(1, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        {
            sirenum__Timesheet__c record = scenario.adjustmentTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Adjustment', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(55, lineRecord.sirenum__Charge__c, 'Charge should have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }

        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of reversal lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    @isTest
    static void adjust_givenAdjustmentsToPayRateAndChargeRate_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.lines = new List<TimesheetAdjustmentService.AdjustmentTimesheetLine>();

        TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine1 = new TimesheetAdjustmentService.AdjustmentTimesheetLine();
        adjustmentLine1.timesheetLineId = scenario.timesheet1Line1.Id;
        adjustmentLine1.chargeRate = 45;
        adjustmentLine1.payRate = 65;

        request.timesheet.lines.add(adjustmentLine1);

        Test.startTest();
        TimesheetAdjustmentService.adjust(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            scenario.timesheet1.Id,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(1, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        {
            sirenum__Timesheet__c record = scenario.adjustmentTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Adjustment', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(45, lineRecord.sirenum__Charge__c, 'Charge should have been updated');
                Assert.areEqual(65, lineRecord.sirenum__Rate__c, 'Rate should have been updated');
            }
        }

        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of reversal lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    @isTest
    static void adjust_givenAdjustmentsToPayInTimePayElement_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.lines = new List<TimesheetAdjustmentService.AdjustmentTimesheetLine>();

        TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine1 = new TimesheetAdjustmentService.AdjustmentTimesheetLine();
        adjustmentLine1.timesheetLineId = scenario.timesheet1Line1.Id;
        adjustmentLine1.inTimePayElement = 'INSURANCE SERVICES';

        request.timesheet.lines.add(adjustmentLine1);

        Test.startTest();
        TimesheetAdjustmentService.adjust(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            scenario.timesheet1.Id,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(1, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        {
            sirenum__Timesheet__c record = scenario.adjustmentTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'INSURANCE SERVICES',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Adjustment', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should have been updated');
            }
        }

        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of reversal lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    @isTest
    static void reverse_givenAdjustmentsToPayRateAndChargeRate_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.lines = new List<TimesheetAdjustmentService.AdjustmentTimesheetLine>();

        TimesheetAdjustmentService.AdjustmentTimesheetLine adjustmentLine1 = new TimesheetAdjustmentService.AdjustmentTimesheetLine();
        adjustmentLine1.timesheetLineId = scenario.timesheet1Line1.Id;
        adjustmentLine1.chargeRate = 45;
        adjustmentLine1.payRate = 65;

        request.timesheet.lines.add(adjustmentLine1);

        Test.startTest();
        TimesheetAdjustmentService.reverse(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            null,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(0, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    @isTest
    static void adjust_givenAdjustmentsToPoNumber_createsCorrectAdjustmentAndTimesheets() {
        TestScenario scenario = new TestScenario();

        TimesheetAdjustmentService.AdjustmentRequest request = new TimesheetAdjustmentService.AdjustmentRequest();
        request.timesheet = new TimesheetAdjustmentService.AdjustmentTimesheet();
        request.timesheet.timesheetId = scenario.timesheet1.Id;
        request.timesheet.poNumber = 'Updated-PO-Number';

        Test.startTest();
        TimesheetAdjustmentService.adjust(new List<TimesheetAdjustmentService.AdjustmentRequest>{ request });
        Test.stopTest();

        scenario.gatherAdjustments();

        List<Sirenum__Timesheet__c> original = [
            SELECT Id, Timesheet_Type__c, Adjustment__c
            FROM sirenum__Timesheet__c
            WHERE Id = :scenario.timesheet1.Id
        ];

        Assert.areEqual(1, scenario.adjustmentRecords.size(), 'Should have correct number adjustment records');
        {
            Timesheet_Adjustment__c record = scenario.adjustmentRecords.get(0);
            Assert.areEqual('Adjustment', record.Type__c, 'Adjustment record should be of correct type');
        }

        Timesheet_Adjustment__c adjustmentRecord = scenario.adjustmentRecords.get(0);

        Assert.areEqual(
            scenario.timesheet1.Id,
            scenario.shift1.sirenum__Timesheet_summaries__c,
            'Should have set timesheet summaries correctly'
        );
        Assert.areEqual(
            adjustmentRecord.Id,
            scenario.shift1.Timesheet_Adjustment__c,
            'Should have set adjustment id correctly'
        );
        Assert.areEqual(
            scenario.timesheet1.id,
            scenario.shift1.Original_Timesheet__c,
            'Should have set original timesheet id correctly'
        );

        Assert.areEqual(1, original.size(), 'Should have correct number of adjusted timesheets');
        {
            sirenum__Timesheet__c record = original.get(0);
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Original timesheet should lookup to correct adjustment'
            );
            Assert.areEqual('Adjusted', record.Timesheet_Type__c, 'Original timesheet should be of correct type');
        }

        Assert.areEqual(1, scenario.adjustmentTimesheets.size(), 'Should have correct number of adjustment timesheets');
        {
            sirenum__Timesheet__c record = scenario.adjustmentTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Updated-PO-Number',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of adjustment lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Adjustment', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }

        Assert.areEqual(1, scenario.reversalTimesheets.size(), 'Should have correct number of reversal timesheets');
        {
            sirenum__Timesheet__c record = scenario.reversalTimesheets.get(0);
            Assert.areNotEqual(
                scenario.timesheet1.Id,
                record.Id,
                'Should have a different id from the original timesheet'
            );
            Assert.areEqual(
                adjustmentRecord.Id,
                record.Adjustment__c,
                'Adjusted timesheet should lookup to correct adjustment'
            );
            Assert.areEqual(
                'Test-PO-1',
                record.sirenum__PO_Number__c,
                'Adjusted timesheet should have correct PO number'
            );

            List<sirenum__Timesheet_Line__c> lineRecords = record.sirenum__Timesheet_Lines__r;
            Assert.areEqual(1, lineRecords.size(), 'Should have the correct number of reversal lines');

            {
                sirenum__Timesheet_Line__c lineRecord = lineRecords.get(0);
                Assert.areNotEqual(
                    scenario.timesheet1Line1.Id,
                    lineRecord.Id,
                    'Should have a different id from the original timesheet line'
                );
                Assert.areEqual(
                    'ADJUSTMENT NOHP',
                    lineRecord.IntimePayElement__c,
                    'Should have a correct intime pay element value'
                );

                Assert.areEqual('Reversal', lineRecord.Timesheet_Type__c, 'Should have correct timesheet line type');
                Assert.areEqual(-10, lineRecord.sirenum__Hours__c, 'Hours should be correct');
                Assert.areEqual(5, lineRecord.sirenum__Charge__c, 'Charge should not have been updated');
                Assert.areEqual(100, lineRecord.sirenum__Rate__c, 'Rate should not have been updated');
            }
        }
    }

    class TestScenario {
        public sirenum__Shift__c shift1 { get; set; }
        public sirenum__Timesheet__c timesheet1 { get; private set; }
        public sirenum__Timesheet_Line__c timesheet1Line1 { get; private set; }
        public List<sirenum__Timesheet__c> adjustmentTimesheets { get; private set; }
        public List<sirenum__Timesheet__c> reversalTimesheets { get; private set; }
        public List<Timesheet_Adjustment__c> adjustmentRecords { get; private set; }

        public TestScenario() {
            adjustmentTimesheets = new List<sirenum__Timesheet__c>();
            reversalTimesheets = new List<sirenum__Timesheet__c>();

            Contact worker = new Contact(FirstName = 'Joe', LastName = 'Bloggs');
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

            shift1 = new sirenum__Shift__c(
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

            timesheet1 = new sirenum__Timesheet__c(
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

            timesheet1Line1 = new sirenum__Timesheet_Line__c(
                sirenum__Timesheet__c = timesheet1.Id,
                sirenum__Hours__c = 10,
                sirenum__Rate__c = 100.0,
                sirenum__Charge__c = 5,
                sirenum__Shift__c = shift1.Id,
                IntimePayElement__c ='ADJUSTMENT NOHP',
                sirenum__Date__c = Date.newInstance(2022, 1, 3)
            );

            sirenum__Timesheet_Line__c timesheetLine2 = new sirenum__Timesheet_Line__c(
                sirenum__Timesheet__c = timesheet2.Id,
                sirenum__Hours__c = 11,
                sirenum__Rate__c = 101.0,
                sirenum__Charge__c = 8,
                sirenum__Shift__c = shift2.Id,
                IntimePayElement__c ='ADJUSTMENT NOHP',
                sirenum__Date__c = Date.newInstance(2022, 1, 2)
            );

            insert new List<SObject>{ timesheet1Line1, timesheetLine2 };

            shift1.sirenum__Timesheet_summaries__c = timesheet1.Id;
            update shift1;
        }

        public void gatherAdjustments() {
            adjustmentTimesheets = [
                SELECT
                    Id,
                    Timesheet_Type__c,
                    Adjustment__c,
                    sirenum__PO_Number__c,
                    (
                        SELECT
                            Id,
                            sirenum__Rate__c,
                            sirenum__Charge__c,
                            Timesheet_Type__c,
                            sirenum__Hours__c,
                            IntimePayElement__c
                        FROM sirenum__Timesheet_Lines__r
                        ORDER BY Timesheet_Type__c DESC
                    )
                FROM sirenum__Timesheet__c
                WHERE Timesheet_Type__c = 'Adjustment'
            ];

            reversalTimesheets = [
                SELECT
                    Id,
                    Timesheet_Type__c,
                    Adjustment__c,
                    sirenum__PO_Number__c,
                    (
                        SELECT
                            Id,
                            sirenum__Rate__c,
                            sirenum__Charge__c,
                            Timesheet_Type__c,
                            sirenum__Hours__c,
                            IntimePayElement__c
                        FROM sirenum__Timesheet_Lines__r
                        ORDER BY Timesheet_Type__c DESC
                    )
                FROM sirenum__Timesheet__c
                WHERE Timesheet_Type__c = 'Reversal'
            ];

            shift1 = [
                SELECT Id, sirenum__Timesheet_summaries__c, Timesheet_Adjustment__c, Original_Timesheet__c
                FROM sirenum__Shift__c
                WHERE Id = :shift1.Id
            ];

            adjustmentRecords = [
                SELECT Id, Type__c
                FROM Timesheet_Adjustment__c
            ];
        }
    }
}