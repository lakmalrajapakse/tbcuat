@isTest
private class ShiftReportPDFControllerTest {

    @testSetup
    static void setup() {
        // Create Contact
        Contact c = new Contact(FirstName = 'Test', LastName = 'User');
        insert c;

        // Create Timesheet
        //SObjectType timesheetType = Schema.getGlobalDescribe().get('sirenum__Timesheet__c');
        sirenum__Timesheet__c timesheet = new sirenum__Timesheet__c();
        timesheet.sirenum__Worker__c=c.Id;
        insert timesheet;

        // Create Shifts
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();
        for (Integer i = 0; i < 3; i++) {
            shifts.add(new sirenum__Shift__c(
                sirenum__Contact__c = c.Id,
                sirenum__Timesheet_summaries__c = timesheet.Id,
                sirenum__Scheduled_Start_Time__c = System.now().addHours(i),
                sirenum__Scheduled_End_Time__c = System.now().addHours(i + 1)
            ));
        }
        insert shifts;
    }

    @isTest
    static void testController() {
        Id timesheetId = [SELECT Id FROM sirenum__Timesheet__c LIMIT 1].Id;
        List<sirenum__Shift__c> shifts = [
            SELECT Id FROM sirenum__Shift__c
            WHERE sirenum__Timesheet_summaries__c = :timesheetId
        ];

        String shiftIdsParam = String.join(new List<String>{
            shifts[0].Id, shifts[1].Id
        }, ',');

        PageReference pageRef = Page.ShiftReportPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('timesheetId', String.valueOf(timesheetId));
        ApexPages.currentPage().getParameters().put('shiftIds', shiftIdsParam);

        ShiftReportPDFController controller = new ShiftReportPDFController();

        System.assertEquals(timesheetId, controller.timesheetId);
        System.assert(controller.shifts.size() > 0, 'Shifts should be loaded for the controller');
    }
}