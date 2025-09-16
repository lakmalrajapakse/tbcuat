@isTest
public class DAVIS_CheckDrivingLicenseInvokerTest {

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
    
        Contact c = new Contact(
            FirstName = 'Driver',
            LastName = 'One',
            Davis_Id__c = 'DV123456',
            Davis_Status__c = 'Active',
            Next_Check_Date__c = Date.today().addDays(-1)
        );
        insert c;
    }
    

    @isTest
    static void testCheckDriver_Successful() {
        Contact c = [SELECT Id FROM Contact WHERE Davis_Id__c != null LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CheckDrivingLicenseHttpMock());

        Test.startTest();
        DAVIS_CheckDrivingLicenseInvoker.checkDriver(c);
        Test.stopTest();

        // Verify updates and inserts
        Contact updated = [SELECT Davis_Status__c, Next_Check_Date__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Active', updated.Davis_Status__c);
    }

}