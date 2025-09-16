@IsTest
public with sharing class SIM_ShiftProcessorOvertime_test {
    static Account acc;
    static Contact con;
    static Bank_Details__C bankDetail;
    static Contact clientContact;
    static sirenum__ProActiveContract__c contract;
    static sirenum__Site__c site;
    static sirenum__Team__c team;
    static TR1__Job__c job;
    static sirenum__Placement__c placement;
    static sirenum__Rate_card__c rateCard;
    static DateTime testDateTime;
    static Date testDate;
    static List<sirenum__Payroll_Cycle__c> testCycles;
    static List<sirenum__Week__c> testPeriods;
    static List<sirenum__Shift__c> testShifts;


    static void createTestData(){
        acc = SIM_TestDataFactory.genTestAccount('Candidate Pool', 'Candidate Pool', true);

        Id candidateRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Candidate').getRecordTypeId();
        Id clientRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client').getRecordTypeId();

        con = new Contact(FirstName = 'tot', LastName = 'brown', AccountId = acc.Id, RecordTypeId = candidateRT,  email='abc@abc.com');
        con.InTimeExternalId__c = 'extId1';
        clientContact = new Contact(FirstName = 'Ridge2', LastName = 'grwon', AccountId = acc.Id, RecordTypeId = clientRT, email='abc@abc.com');

        insert new List<Contact> {con, clientContact};
        
        site = SIM_TestDataFactory.genTestSite(acc, true);

        contract = SIM_TestDataFactory.genTestContract(acc, clientContact, acc, true);

        team = SIM_TestDataFactory.genTestJobRole(contract, false);
        team.sirenum__AWR_Group__c= sirenum__Team__c.sirenum__AWR_Group__c.getDescribe().getPicklistValues().get(0).getValue();
        insert team;

        testDateTime = dateTime.newInstance(2024, 2, 14, 9,0,0);
        testDate = date.newInstance(2024, 2, 14);

                
        testCycles = new List<sirenum__Payroll_Cycle__c>{
            SIM_TestDataFactory.getTestCycle('Cycle 1')
        };
        testCycles[0].sirenum__StartingDate__c = date.newInstance(2024, 2, 3);
        insert testCycles;

        contract.sirenum__PayrollCycle__c = testCycles[0].id;
        update contract;

        testPeriods = new List<sirenum__Week__c>{
            SIM_TestDataFactory.getTestPeriod(testCycles[0].id, testDateTime.date())            
        };
        insert testPeriods;

        testShifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime,
                sirenum__Scheduled_End_Time__c = testDateTime.addHours(1),
                sirenum__Published__c = false,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1
            ),
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(1),
                sirenum__Published__c = false,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1
            ),
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(4),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(4).addHours(1),
                sirenum__Published__c = false,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1
            ),
            new sirenum__Shift__c(
                sirenum__Contact__c = con.id,
                sirenum__Site__c = site.id,
                sirenum__Team__c = team.id,
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(4).addHours(8),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(4).addHours(9),
                sirenum__Published__c = false,
                sirenum__Contract__c = contract.id,
                sirenum__Accepted__c = 1
            )
        };

        insert testShifts;
    }

    @IsTest
    static void testRequiredFields() {
        SIM_ShiftProcessorOvertime overtimePlugin = new SIM_ShiftProcessorOvertime();
        Set<String> requiredFieldPaths = overtimePlugin.getRequiredFieldPaths((new sirenum.ShiftProcessorOvertimeContextBuilder()).build());
        System.assertEquals(4, requiredFieldPaths.size());
        System.assertEquals(true, requiredFieldPaths.contains('sirenum__Billable_Calculated_Start_Time__c'));
        System.assertEquals(true, requiredFieldPaths.contains('sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c'));
    }

    @IsTest
    static void testGetStartOfWeekFor() {

        createTestData();
        

        SIM_ShiftProcessorOvertime overtimePlugin = new SIM_ShiftProcessorOvertime();

        // Retrieve shifts with all values required by called method
        List<sirenum__Shift__c> retrievedShifts = [
                SELECT Id,
                       Name,
                       sirenum__Team__r.sirenum__Account__r.sirenum__Client__c,                               
                       sirenum__Billable_Calculated_Start_Time__c,                               
                       sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c
                FROM sirenum__Shift__c
                WHERE Id IN :testShifts
                ORDER BY sirenum__Scheduled_Start_Time__c
        ];
        
        DateTime startOfWeek = overtimePlugin.getStartOfWeekFor(retrievedShifts[0], (new sirenum.ShiftProcessorOvertimeContextBuilder()).build());
        System.assertEquals(Date.newInstance(2024, 2, 10), startOfWeek.date());
    }

    @IsTest
    static void coveringTest() {
        createTestData();
        

        SIM_ShiftProcessorOvertime overtimePlugin = new SIM_ShiftProcessorOvertime();

        // Retrieve shifts with all values required by called method
        List<sirenum__Shift__c> retrievedShifts = [
                SELECT Id,
                       Name,
                       sirenum__Team__r.sirenum__Account__r.sirenum__Client__c,                               
                       sirenum__Billable_Calculated_Start_Time__c,                               
                       sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c
                FROM sirenum__Shift__c
                WHERE Id IN :testShifts
                ORDER BY sirenum__Scheduled_Start_Time__c
        ];


        DateTime startOfDay = overtimePlugin.getStartOfDayFor(retrievedShifts[0], (new sirenum.ShiftProcessorOvertimeContextBuilder()).build());
        System.assertEquals(null, startOfDay);
    }

    @IsTest
    static void testIsNomineeRelevantAsPastWork() {

        createTestData();

        SIM_ShiftProcessorOvertime overtimePlugin = new SIM_ShiftProcessorOvertime();        

        Boolean isNomineeRelevantAsPastWork;

        // Retrieve shifts with all values required by called method
        List<sirenum__Shift__c> retrievedShifts = [
                SELECT Id,
                       Name,
                       sirenum__Team__r.sirenum__Account__r.sirenum__Client__c,                               
                       sirenum__Billable_Calculated_Start_Time__c,                               
                       sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__r.sirenum__StartingDate__c
                FROM sirenum__Shift__c
                WHERE Id IN :testShifts
                ORDER BY sirenum__Scheduled_Start_Time__c
        ];

        isNomineeRelevantAsPastWork = overtimePlugin.isNomineeRelevantAsPastWork(
                  retrievedShifts[0],
                  retrievedShifts[1],
                  null,
                  (new sirenum.ShiftProcessorOvertimeContextBuilder()).build()
                ); 

        System.assertEquals(true, isNomineeRelevantAsPastWork);
    }    
}