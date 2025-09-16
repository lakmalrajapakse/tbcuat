@isTest
private class AccountClientCodeTriggerHandlerTest {
    Account client;

    @isTest
    static void test_existingPrefix() {
        createData();
        Account client = new Account(Name = 'ABCD Services');
        Test.startTest();
        insert client;
        Test.stopTest();
        Account testClient = [SELECT Id, Client_Code__c FROM Account WHERE Id = :client.Id];
        System.debug('testClient: ' + testClient);
        System.Assert.areEqual('ABCD4001', testClient.Client_Code__c);
    }

    @isTest
    static void test_noPrefix() {
        Account client = new Account(Name = 'ABCD Services');
        Test.startTest();
        insert client;
        Test.stopTest();
        Account testClient = [SELECT Id, Client_Code__c FROM Account WHERE Id = :client.Id];
        System.debug('testClient: ' + testClient);
        System.Assert.areEqual('ABCD4000', testClient.Client_Code__c);
    }

    @isTest
    static void test_shortCode() {
        Account client = new Account(Name = 'ABC');
        Test.startTest();
        insert client;
        Test.stopTest();
        Account testClient = [SELECT Id, Client_Code__c FROM Account WHERE Id = :client.Id];
        System.debug('testClient: ' + testClient);
        System.Assert.areEqual('ABCZ4000', testClient.Client_Code__c);
    }


    static void createData(){
        Client_Code_Prefix__c clientCodePrefix = new Client_Code_Prefix__c(
            Client_Code_Prefix__c = 'ABCD',
            Client_Code_Number__c = 4000
        );
        System.debug('clientCodePrefix: ' + clientCodePrefix);
        insert clientCodePrefix;

    }
}