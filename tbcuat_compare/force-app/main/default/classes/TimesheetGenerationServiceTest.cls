@isTest
public with sharing class TimesheetGenerationServiceTest {
    @isTest
    static void processPay_whenTaskIsMissing_willThrowCorrectException() {
        Date startDate = Date.newInstance(2022, 1, 1);
        Date endDate = Date.newInstance(2022, 1, 31);

        try {
            Test.startTest();

            TimesheetGenerationService.ProcessPayRequest request = new TimesheetGenerationService.ProcessPayRequest();
            request.startDate = startDate;
            request.endDate = endDate;
            TimesheetGenerationService.processPay(request);

            System.assert(false, 'Should have thrown an exception');
        } catch (Exception ex) {
            System.assertEquals(
                'No timesheet generation task found',
                ex.getMessage(),
                'Should have the correct exception message'
            );
        } finally {
            Test.stopTest();
        }
    }

    @isTest
    static void processPay_givenBasicConfig_willUpdateScheduledTask() {
        createScheduledTask();

        Date startDate = Date.newInstance(2022, 1, 1);
        Date endDate = Date.newInstance(2022, 1, 31);

        TimesheetGenerationService.ProcessPayRequest request = new TimesheetGenerationService.ProcessPayRequest();
        request.startDate = startDate;
        request.endDate = endDate;

        Test.startTest();
        TimesheetGenerationService.processPay(request);
        Test.stopTest();

        sirenum__Scheduled_Task__c task = [
            SELECT Id, sirenum__Configuration__c
            FROM sirenum__Scheduled_Task__c
            WHERE sirenum__Task_Type__c = 'Timesheet Generation'
        ];

        System.assertEquals(
            '{"period":{"selectionClause":"sirenum__Start_Date__c >= 2022-01-01 AND sirenum__Week_Ending__c <= 2022-01-31","orderByClause":"sirenum__Week_Ending__c DESC"},"notify":"DO NOT SEND","filter":{}}',
            task.sirenum__Configuration__c,
            'Should update task with correct config'
        );
    }

    @isTest
    static void processPay_givenFilters_willUpdateScheduledTask() {
        createScheduledTask();

        Date startDate = Date.newInstance(2022, 1, 1);
        Date endDate = Date.newInstance(2022, 1, 31);

        TimesheetGenerationService.ProcessPayRequest request = new TimesheetGenerationService.ProcessPayRequest();
        request.startDate = startDate;
        request.endDate = endDate;
        request.filters.contactNames.add('Test Contact 1');
        request.filters.contactNames.add('Test Contact 2');
        request.filters.siteNames.add('Test Site 1');
        request.filters.siteNames.add('Test Site 2');
        request.filters.roleNames.add('Test Role 1');
        request.filters.roleNames.add('Test Role 2');

        Test.startTest();
        TimesheetGenerationService.processPay(request);
        Test.stopTest();

        sirenum__Scheduled_Task__c task = [
            SELECT Id, sirenum__Configuration__c
            FROM sirenum__Scheduled_Task__c
            WHERE sirenum__Task_Type__c = 'Timesheet Generation'
        ];

        System.assertEquals(
            '{"period":{"selectionClause":"sirenum__Start_Date__c >= 2022-01-01 AND sirenum__Week_Ending__c <= 2022-01-31","orderByClause":"sirenum__Week_Ending__c DESC"},"notify":"DO NOT SEND",' +
            '"filter":{"Team__c":["Test Role 1","Test Role 2"],"Site__c":["Test Site 1","Test Site 2"],"Contact__c":["Test Contact 1","Test Contact 2"]}}',
            task.sirenum__Configuration__c,
            'Should update task with correct config'
        );
    }

    private static void createScheduledTask() {
        sirenum__Scheduled_Task__c task = new sirenum__Scheduled_Task__c(
            Name = 'Execute Timesheet Creation',
            sirenum__Task_Type__c = 'Timesheet Generation'
        );
        insert task;
    }
}