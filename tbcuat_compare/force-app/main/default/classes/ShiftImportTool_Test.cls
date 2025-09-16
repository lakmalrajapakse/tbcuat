@isTest
public class ShiftImportTool_Test {

    private static sirenum__Site__c site;
    private static sirenum__Rota__c rota;
    private static sirenum__Team__c team;
    private static Contact con;

    private static sirenum__Site__c site2;
    private static sirenum__Rota__c rota2;
    private static sirenum__Team__c team2;
    private static Contact con2;

    private static ShiftImportLog__c itdc;
    private static Account acc;
    private static ShiftImportSettings__c its;

    private static contract contract;
    private static sirenum__Payroll_Cycle__c paycycle;

    private static void createTestData() {
        //TEST RECORDS  
        site = new sirenum__Site__c(Name = 'test Site');
        insert site;
        rota = new sirenum__Rota__c(Name = 'test ROTA');
        insert rota;
        acc = new Account(Name = 'Test Account', TR1__Status__c = 'Live', Client_Code__c = '99990');
        insert acc;
        con = new Contact(FirstName = 'John', LastName = 'User', Email = 'test@sirenum.com', MobilePhone = '07583331473', AccountId = acc.Id);
        insert con;
        paycycle = new sirenum__Payroll_Cycle__c(Name = 'Sunday - Monday', sirenum__CyclePeriodUnits__c = 'Weeks', sirenum__periodLength__c = 1, sirenum__StartingDate__c = system.today());
        insert paycycle;
        contract = new Contract(Name = 'BBF Hull', AccountId = acc.Id, Status = 'Draft');
        insert contract;
        sirenum__ProActiveContract__c wfm_Contract = new sirenum__ProActiveContract__c(name='wfm contract',sirenum__Client__c=acc.id);
        insert wfm_contract;
        team = new sirenum__Team__c(Name = '99990 - test TEAM', sirenum__Account__c = wfm_contract.Id); // was contract id but this org needed the other kind of contract   
        insert team;



        //Secondary Records
        site2 = new sirenum__Site__c(Name = 'test Site2');
        insert site2;
        rota2 = new sirenum__Rota__c(Name = 'test ROTA2');
        insert rota2;
        team2 = new sirenum__Team__c(Name = 'test TEAM2');
        insert team2;
        con2 = new Contact(FirstName = 'Jane', LastName = 'OtherUser', Email = generateRandomString(5,false)+'@sirenum.com',
        MobilePhone = '07583331473',
        sirenum__National_Insurance__c=generateRandomString(9,true),
        AccountId = acc.Id);
        insert con2;


        Schema.DescribeFieldResult cancellationReasonsDescribe = sirenum__Shift__c.sirenum__CancellationReason__c.getDescribe();
        Schema.SObjectField T = cancellationReasonsDescribe.getSobjectField();
        List<PicklistEntry> entries = T.getDescribe().getPicklistValues();

        //DB Object
        itdc = new ShiftImportLog__c();

        //Settings
        its = new ShiftImportSettings__c();
        its.Match_Accounts__c = 'Name';
        its.Match_Contacts__c = 'Name';
        its.Match_Job_Roles__c = 'Name';
        its.Match_Rotas__c = 'Name';
        its.Match_Shifts__c = 'sirenum__FMS_Shift_ID__c';
        its.Match_Sites__c = 'Name';
        its.Default_Cancellation_Reason__c = entries.get(0).getValue();

        insert its;

    }

    private static String generateRandomString(Integer length,boolean isnumber) {
        final String CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        final String NUMBERS = '0123456789';
        String result = '';
        for (Integer i = 0; i < length; i++) {

            if(isnumber==false){
                Integer randomIndex = Math.mod(Math.round(Math.random() * 1000), CHARACTERS.length());
                result += CHARACTERS.substring(randomIndex, randomIndex + 1);
            }
            else{

                Integer randomIndex = Math.mod(Math.round(Math.random() * 1000), NUMBERS.length());
                result += NUMBERS.substring(randomIndex, randomIndex + 1);

            }

        }
        return result;
    }

    static testmethod void testFailures() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        //Improt shift demand against a worker
        String jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "01/01/2016","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE","ACTUAL START DATE":"01/06/2020","ACTUAL END DATE":"02/06/2020","ACTUAL END TIME":"20:00","ACTUAL START TIME":"x","BILLABLE START DATE":"02/06/2020","BILLABLE END DATE":"02/06/2020","BILLABLE END TIME":"23:00","BILLABLE START TIME":"22:00","APPROVED":"TRUE"}]}';
        List<ShiftImportTool.infoRow> returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('cannot be assigned to'));

        //Now insert the demand
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "","DATE": "01/01/2016","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals('Inserted Shift Demand [Requirement]', returnRows[0].infoMessage);

        //Attempt to update shift demand - fail due to duplicate shifts with the reference number
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "","DATE": "01/01/2016","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());

        //Duplicate Sites/Jobs/Rotas/Contacts
        sirenum__Site__c site3 = new sirenum__Site__c(Name = 'test Site');
        insert site3;
        sirenum__Rota__c rota3 = new sirenum__Rota__c(Name = 'test ROTA');
        insert rota3;
        sirenum__Team__c team3 = new sirenum__Team__c(Name = 'test TEAM');
        insert team3;
        Contact con3 = new Contact(FirstName = 'John', LastName = 'User', Email = 'test2@sirenum.com', MobilePhone = '07583331470', AccountId = acc.Id);
        insert con3;

        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "01/01/2016","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
    }

    static testmethod void testDataIntegrity() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        //Bad or missing data
        String jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "2024-03-03","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "", "END": "A","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        List<ShiftImportTool.infoRow> returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        // System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('Invalid Date:'));
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('No start time'));

        //Bad end time
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07", "END": "A","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('Bad End time'));
        //Bad end time
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "A", "END": "13","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('Bad Start time'));

        its.Match_Shifts__c = 'Name';
        update its;
        //Bad Field
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07", "END": "13","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        try {
            returnRows = ShiftImportTool.parse(jsnString);
        } catch (Exception e) {
            System.assertEquals(true, e.getMessage().containsIgnoreCase('Field Name is not editable'));
        }


    }

    static testmethod void testHeadersAndDataBase() {
        createTestData();

        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.Header_Columns__c = '';// USING DEFAULT SETTINGS 'REFERENCE, WORKER, JOB ROLE, SITE, ROTA, DATE, START, END, REQUIRED SHIFTS, COMMENTS, CANCELLED, LOCATION, PO NUMBER, ACTUAL START DATE, ACTUAL START TIME, ACTUAL END DATE, ACTUAL END TIME, BILLABLE START DATE, BILLABLE START TIME, BILLABLE END DATE, BILLABLE END TIME, APPROVED, Result';
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);
        String jsnString = '{"importFile": [{"REF": "1234","WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE","LOCATION":"test location","PO NUMBER":"555553"}]}';

        List<ShiftImportTool.infoRow> returnRows = new List<ShiftImportTool.infoRow>();
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());

        List<ShiftImportLog__c> itd = [
                select Id, Successes__c, Errors__c,Success_Deletions__c, Error_Deletions__c
                from ShiftImportLog__c
        ];
        System.assertEquals(1, itd.size());

    }

    static testmethod void testTempSettings() {
        createTestData();

        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = false;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        String userName = UserInfo.getUserName();
        User activeUser = [Select Email From User where Username = :userName limit 1];
        System.assertEquals(activeUser.Email, controller.tSettings.emailRecipient);

    }
    static testmethod void testDelete() {
        createTestData();

        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = false;
        its.Import_Shifts__c = true;
        its.Send_Email_Results__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        sirenum__Shift__c shift = new sirenum__Shift__c(sirenum__Contact__c = con.Id, sirenum__Team__c = team.Id, sirenum__Site__c = site.Id, sirenum__Rota__c = rota.Id, sirenum__Scheduled_Start_Time__c = system.today(), sirenum__Scheduled_End_Time__c = system.today());
        insert shift;
        String shiftId = shift.Id;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        Integer expectedLimits = 0;
        Integer actualLimits = Limits.getEmailInvocations();

        controller.tSettings.deleteLines = shift.Id;
        controller.doDelete();

        expectedLimits = 0;
        actualLimits = Limits.getEmailInvocations();
        //We are not sending an email in test
        System.assertEquals(expectedLimits, actualLimits, 'wrong limits after');

        List<sirenum__Shift__c> shiftsDeleted = [select Id from sirenum__Shift__c];
        System.assertEquals(0, shiftsDeleted.size());

    }

    static testmethod void testParsing() {
        createTestData();

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);
        String jsnString = '{"importFile": [{"REFERENCE": "1234", "WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "Some team","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';

        ShiftImportTool.parse(jsnString);

        //Create date
        Integer d = 01;
        Integer mo = 01;
        Integer yr = 2016;

        Date DATES = Date.newInstance(yr, mo, d);
        Datetime schStart = Datetime.newInstance(DATES, Time.newInstance(07, 30, 0, 0));
        Datetime schEnd = Datetime.newInstance(DATES, Time.newInstance(09, 30, 0, 0));

        System.assertEquals('1234', ShiftImportTool.rows.get(0).shiftReferenceN);
        System.assertEquals('test Site', ShiftImportTool.rows.get(0).shiftStation);
        System.assertEquals('John User', ShiftImportTool.rows.get(0).shiftContact);
        System.assertEquals('test ROTA', ShiftImportTool.rows.get(0).shiftRota);
        System.assertEquals('07:30', ShiftImportTool.rows.get(0).shiftAcStart);
        System.assertEquals('09:30', ShiftImportTool.rows.get(0).shiftAcEnd);
        System.assertEquals(2, ShiftImportTool.rows.get(0).shiftDemands);
        System.assertEquals('A comment', ShiftImportTool.rows.get(0).shiftComments);
        System.assertEquals('No', ShiftImportTool.rows.get(0).shiftCancelled);
        System.assertEquals(DATES, ShiftImportTool.rows.get(0).shiftDate_parsed);


    }

    static testmethod void testImportShiftRequirementAndDemand() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        its.Send_Email_Results__c = true;
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);
        String jsnString = '{"importFile": [{"REFERENCE": "1234","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';

        Integer expectedLimits = 0;
        Integer actualLimits = Limits.getEmailInvocations();

        List<ShiftImportTool.infoRow> returnRows = new List<ShiftImportTool.infoRow>();
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals('Inserted Shift [Requirement]', returnRows[0].infoMessage);

        //Test emails
        expectedLimits = 0;
        actualLimits = Limits.getEmailInvocations();
        //We are not sending an email in test
        System.assertEquals(expectedLimits, actualLimits, 'wrong limits after');


        //Create date
        Integer d = 01;
        Integer mo = 01;
        Integer yr = 2016;
        Date DATES = Date.newInstance(yr, mo, d);
        Datetime schStart = Datetime.newInstance(DATES, Time.newInstance(07, 30, 0, 0));
        Datetime schEnd = Datetime.newInstance(DATES, Time.newInstance(09, 30, 0, 0));

        List<sirenum__Shift__c> newShifts = [
                select Id, Name, sirenum__Scheduled_Start_Time__c, sirenum__Comments_By__c, sirenum__Scheduled_End_Time__c, sirenum__Scheduling_Comments__c, sirenum__Comments__c,
                        sirenum__Team__c, sirenum__Site__c, sirenum__Rota__c, sirenum__FMS_Shift_ID__c, sirenum__Cancelled__c, sirenum__CancellationReason__c, sirenum__Broadcasts__c
                from sirenum__Shift__c
        ];

        System.assertEquals(1, newShifts.size());

        System.assertEquals(schStart, newShifts.get(0).sirenum__Scheduled_Start_Time__c);
        System.assertEquals(schEnd, newShifts.get(0).sirenum__Scheduled_End_Time__c);
        System.assertEquals('1234', newShifts.get(0).sirenum__FMS_Shift_ID__c);
        System.assertEquals(site.Id, newShifts.get(0).sirenum__Site__c);
        System.assertEquals(rota.Id, newShifts.get(0).sirenum__Rota__c);
        System.assertEquals('AUTO', newShifts.get(0).sirenum__Comments_By__c);
        System.assertEquals(null, newShifts.get(0).sirenum__Broadcasts__c);
        System.assertEquals(false, newShifts.get(0).sirenum__Cancelled__c);

        //Results Rows
        System.assertEquals('1234', returnRows.get(0).infoReference);
        System.assertEquals('test ROTA', returnRows.get(0).infoRota);
        System.assertEquals('test Site', returnRows.get(0).infoSite);
        System.assertEquals('test Site', returnRows.get(0).infoSite);
        System.assertEquals('07:30', returnRows.get(0).infoStart);
        System.assertEquals('09:30', returnRows.get(0).infoEnd);
        System.assertEquals(String.valueOf(Date.newInstance(2016, 1, 1).format()), returnRows.get(0).infoDate);
        System.assertEquals('Inserted Shift [Requirement]', returnRows.get(0).infoMessage);

        //Try to update the requirement end time - it will be an update as we have provided REFERENCE. 
        jsnString = '{"importFile": [{"REFERENCE": "1234","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "10:30","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        List<ShiftImportTool.infoRow> results = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, results.size());
        System.assertEquals('10:30', results.get(0).infoEnd);

        //Import shift demand
        jsnString = '{"importFile": [{"REFERENCE": "4321","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "10:30","REQUIRED SHIFTS": "2","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        results = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, results.size());

        newShifts = [
                select Id, sirenum__Broadcasts__c
                from sirenum__Shift__c
                where sirenum__Broadcasts__c != null
        ];

        System.assertEquals(1, newShifts.size());
        System.assertEquals(2, newShifts[0].sirenum__Broadcasts__c);

    }

    static testmethod void testImportNamedShift() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);
        String jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "John User","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "09:30","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE","ACTUAL START DATE":"2020-06-01","ACTUAL END DATE":"2020-06-02","ACTUAL END TIME":"20:00","ACTUAL START TIME":"22:00","BILLABLE START DATE":"2020-06-01","BILLABLE END DATE":"2020-06-02","BILLABLE END TIME":"20:00","BILLABLE START TIME":"22:00","APPROVED":"TRUE"}]}'; 

        List<ShiftImportTool.infoRow> returnRows = new List<ShiftImportTool.infoRow>();
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());

        //Create date
        Integer d = 01;
        Integer mo = 01;
        Integer yr = 2016;
        Date DATES = Date.newInstance(yr, mo, d);
        Datetime schStart = Datetime.newInstance(DATES, Time.newInstance(07, 30, 0, 0));
        Datetime schEnd = Datetime.newInstance(DATES, Time.newInstance(09, 30, 0, 0));

        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = schStart,
            sirenum__Scheduled_End_Time__c = schEnd,
            sirenum__FMS_Shift_ID__c = '1234',
            sirenum__Contact__c = con.Id,
            sirenum__Team__c = team.Id,
            sirenum__Site__c = site.id,
            sirenum__Rota__c = rota.id,
            sirenum__Comments_By__c = 'AUTO',
            sirenum__Broadcasts__c = null,
            sirenum__Cancelled__c = false
        );
        insert shift;

        List<sirenum__Shift__c> newShifts = [
            select Id, Name, sirenum__Scheduled_Start_Time__c, sirenum__Comments_By__c, sirenum__Scheduled_End_Time__c, sirenum__Scheduling_Comments__c, sirenum__Comments__c,
                    sirenum__Team__c, sirenum__Site__c, sirenum__Rota__c, sirenum__FMS_Shift_ID__c, sirenum__Cancelled__c, sirenum__CancellationReason__c, sirenum__Broadcasts__c, sirenum__Contact__c
            from sirenum__Shift__c
        ];

        system.debug('SPC newShifts SIMON ' + newShifts);

        System.assertEquals(schStart, newShifts.get(0).sirenum__Scheduled_Start_Time__c);
        System.assertEquals(schEnd, newShifts.get(0).sirenum__Scheduled_End_Time__c);
        System.assertEquals(newShifts.get(0).Name, newShifts.get(0).sirenum__FMS_Shift_ID__c);
        System.assertEquals(con.Id, newShifts.get(0).sirenum__Contact__c);
        //System.assertEquals(team.Id, newShifts.get(0).sirenum__Team__c);
        System.assertEquals(site.Id, newShifts.get(0).sirenum__Site__c);
        System.assertEquals(rota.Id, newShifts.get(0).sirenum__Rota__c);
        System.assertEquals('AUTO', newShifts.get(0).sirenum__Comments_By__c);
        System.assertEquals(null, newShifts.get(0).sirenum__Broadcasts__c);
        System.assertEquals(false, newShifts.get(0).sirenum__Cancelled__c);

        //Results Rows
        System.assertEquals('1234', returnRows.get(0).infoReference);
        System.assertEquals('test ROTA', returnRows.get(0).infoRota);
        System.assertEquals('test Site', returnRows.get(0).infoSite);
        System.assertEquals('test Site', returnRows.get(0).infoSite);
        System.assertEquals('John User', returnRows.get(0).infoContact);
        System.assertEquals('07:30', returnRows.get(0).infoStart);
        System.assertEquals('09:30', returnRows.get(0).infoEnd);
        System.assertEquals('2016-01-01', returnRows.get(0).infoDate);

        //Try to update the shift end time and remove the worker - it will be an update as we have provided REFERENCE
        jsnString = '{"importFile": [{"REFERENCE": "1234","WORKER": "","DATE": "2016-01-01","SITE": "test Site","ROTA": "test ROTA","JOB": "test TEAM","START": "07:30", "END": "10:30","REQUIRED SHIFTS": "","COMMENTS": "A comment", "CANCELLED": "FALSE"}]}';
        List<ShiftImportTool.infoRow> results = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, results.size());

        newShifts = [
                select Id, sirenum__Contact__c
                from sirenum__Shift__c
        ];
        System.assertEquals(2, newShifts.size());
    }
}