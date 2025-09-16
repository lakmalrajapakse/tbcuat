@isTest
public class DAVIS_ContactHandlerTest {

    @TestSetup
    static void setupTestData() {
        Davis_Integration_Settings__c settings = new Davis_Integration_Settings__c(
            API_KEY__c = 'testapikey',
            Company_Code__c = 'MC09352',
            Authorization__c = 'BASIC 0039zasjdhfhdjfsadkjfdsfds',
            Check_Drivers_endpoint__c = '/check/drivers',
            Check_Drivers_Licence__c = '/check/drivers/licence',
            Full_Check_Drivers_Licence__c ='/check/drivers/full',
            Endpoint__c = 'https://integration.licencedavis.com/'
        );
        insert settings;
           
        Id planCodeRecordTypeId =  Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByName().get('Plan Code').getRecordTypeId();
        Picklist_Library__c pl= new Picklist_Library__c(Davis_Deparment_Id__c = '5343',recordTypeId=planCodeRecordTypeId);
        insert pl;

        Contact contact = new Contact(
            FirstName = 'Test2',
            LastName = 'User2',
            TR1__Candidate_Status__c = 'Registered',
            Plan_Code__c = pl.Id,
            Davis_Id__c = null,
            Next_Check_Date__c = null
        );
        insert contact;

        sirenum__TicketType__c driverType = new sirenum__TicketType__c(
            Name = 'Lorry Driver',
            Competency_Category__c = 'Driver Type',
            external_id__c = '5434'
        );
        insert driverType;

        Sirenum__Ticket__c ticket =  new Sirenum__Ticket__c(
            sirenum__Owner__c = contact.Id,
            sirenum__TicketType__c = driverType.Id,
            sirenum__Valid_from__c = Date.today().addDays(-5),
            sirenum__Valid_until__c = Date.today().addDays(5),
            sirenum__Revoked__c = false


        );
        insert ticket;

        ticket.sirenum__Revoked__c = false;
        update ticket;

    }


    @isTest
    static void testSendDriverDetailsQueueable() {
      
    

        contact con =[select id,DVLA_License_Check__c,plan_Code__c from contact];
        
        con.DVLA_License_Check__c = true;
        update con;

        list<Sirenum__Ticket__c> listTickets= [select id,sirenum__Revoked__c,sirenum__Valid__c,sirenum__Valid_from__c,sirenum__Valid_until__c from Sirenum__Ticket__c];
        system.debug('listTickets: '+listTIckets);
        system.assertNotEquals(true,listTickets.isEmpty());
     
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SendDriverDetailsHttpMock());
        System.enqueueJob(new DAVIS_ContactHandler.SendDriverDetailsQueueableBulk(new List<Contact>{ con }));
        Test.stopTest();

        Contact updatedContact = [SELECT Id,Davis_Id__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('0024341341324321423', updatedContact.Davis_Id__c);
    }

    @isTest
    static void testDeleteDriverQueueableBulk() {
        Test.setMock(HttpCalloutMock.class, new DeleteDriverQueueableHttpMock());

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Davis_Id__c = 'D123456',
            DVLA_License_Check__c = true,
            TR1__Candidate_Status__c = 'Active'
        );
        insert contact;

        contact.TR1__Candidate_Status__c = 'Offboarded';
        contact.LeaverInformationUpdatedInInTime__c = true;
        update contact;

        Test.startTest();
        System.enqueueJob(new DAVIS_ContactHandler.DeleteDriverQueueableBulk(new List<Contact>{ contact }));
        Test.stopTest();
    }

   


    private class CheckDrivingLicenseHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"NextCheckDate":"/Date(1672531200000-0000)/","Entitlements":[{"Status":"Full","Category":"string","Restrictions":"string","CommencedDate":"2025-03-25T11:37:55.247Z","ExpiryDate":"2025-03-25T11:37:55.247Z","Identifier":"string"}],"Endorsements":[{"OffenceDate":"/Date(1672531200000-0000)/","Points":3,"OffenceCode":"SP30","IsDisqualified":true}]}');
            return res;
        }
    }

    private class SendDriverDetailsHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"Driver":{"DriverId":"0024341341324321423","NextCheckDue":"/Date(1672531200000-0000)/"},"Status":{"Code":"string","Success":true}}');
            return res;
        }
    }

    private class DeleteDriverQueueableHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"Status":{"Code":"string","Success":true}}');
            return res;
        }
    }

    private class FailingHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"Status":{"Code":"500","Success":false,"Details":"Internal Server Error"}}');
            return res;
        }
    }
}