@isTest
public class DAVIS_CheckDrivingLicenseBatchTest {
    
    private class CheckDrivingLicenseHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"NextCheckDate":"/Date(1672531200000-0000)/","Entitlements":[{"Status":"Full","Category":"string","Restrictions":"string","CommencedDate":"/Date(1672531200000-0000)/","ExpiryDate":"/Date(1672531200000-0000)/","Identifier":"string"}],"Endorsements":[{"OffenceDate":"/Date(1672531200000-0000)/","Points":3,"OffenceCode":"SP30","IsDisqualified":true}]}');
            return res;
        }
    }

    @testSetup
    static void setupData() {

        Davis_Integration_Settings__c settings = new Davis_Integration_Settings__c(
            API_KEY__c = 'testapikey',
            Company_Code__c = 'MC09352',
            Authorization__c = 'BASIC 0039zasjdhfhdjfsadkjfdsfds',
            Check_Drivers_endpoint__c = '/check/drivers',
            Full_Check_Drivers_Licence__c ='/check/drivers/full',
            Check_Drivers_Licence__c = '/check/drivers/licence',
            Endpoint__c = 'https://integration.licencedavis.com/'
        );
        insert settings;

        Id planCodeRecordTypeId =  Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByName().get('Plan Code').getRecordTypeId();
        Picklist_Library__c pl= new Picklist_Library__c(Davis_Deparment_Id__c = '5343',recordTypeId=planCodeRecordTypeId);
        insert pl;

        // Create Contact that matches batch query criteria
        Contact c = new Contact(
            FirstName = 'Batch',
            LastName = 'Driver',
            Davis_Id__c = '123456',
            Davis_Status__c = 'Active',
            Next_Check_Date__c = Date.today().addDays(-1), // Should be picked up
            Plan_Code__c = pl.Id,
            TR1__Candidate_Status__c = 'Application'
        );
        insert c;

        sirenum__TicketType__c offenceCode = new sirenum__TicketType__c(
            Name = 'SP30',
            external_id__c = '5434',
            Offence_Code__c ='SP30'
        );
        insert offenceCode;

        Sirenum__Ticket__c ticket =  new Sirenum__Ticket__c(
            sirenum__Owner__c = c.Id,
            sirenum__TicketType__c = offenceCode.Id,
            sirenum__Valid_from__c = Date.today().addDays(-5),
            sirenum__Valid_until__c = Date.today().addDays(5),
            Commenced_date__c = Date.today().AddDays(-5),
            Offence_Date__c = Date.today().AddDays(-5)
        );
        insert ticket;

        ticket.sirenum__Revoked__c =false;
        update ticket;

    }

    @isTest
    static void testBatchExecution() {
        // Register mock callout
       

      
        Test.setMock(HttpCalloutMock.class, new CheckDrivingLicenseHttpMock());

        list<Sirenum__Ticket__c> listTickets= [select id,Offence_Date__c,sirenum__Revoked__c,sirenum__Valid__c,sirenum__Valid_from__c,sirenum__Valid_until__c from Sirenum__Ticket__c];
        system.debug('listTickets: '+listTIckets);
        system.assertNotEquals(true,listTickets.isEmpty());

        list<Davis_Error_Log__c> errorLogs = [select id,message__c from Davis_Error_Log__c];
        system.debug('errorLogs test: '+errorLogs);

        
        Test.startTest();
        DAVIS_CheckDrivingLicenseBatch batch = new DAVIS_CheckDrivingLicenseBatch();
        Database.executeBatch(batch, 1); // Use small batch size for unit test

        Test.stopTest();

        // Assert contact updates
        Contact updated = [SELECT Davis_Status__c, Next_Check_Date__c FROM Contact WHERE Davis_Id__c = '123456' LIMIT 1];
        System.assertEquals('Active', updated.Davis_Status__c);

    }
}