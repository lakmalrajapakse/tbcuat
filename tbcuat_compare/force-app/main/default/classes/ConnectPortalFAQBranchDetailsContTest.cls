/**
* @File Name : ConnectPortalFAQBranchDetailsContTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 6, 2025 |   | Initial Version
**/
@isTest
private with sharing class ConnectPortalFAQBranchDetailsContTest {
	private static String communityProfileName = 'TBC Connect Worker Profile - Driving';
    private static String communityUserName = 'communityuser@test.com.test.fake';

	/**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

		Region__c region = new Region__c(Name = 'Test Region');
		insert region;

		Area__c area = new Area__c(Name = 'Test Area', Region__c = region.Id);
		insert area;

		Branch__c branch = new Branch__c(Name = 'Test Branch', Area__c = area.Id);
		insert branch;

        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
		picklistLibrariesList[0].Branch__c = branch.Id;
        insert picklistLibrariesList;

        // Create Account 
        List<Account> accountsList = TestDataCreator.createClients(
            1, 
            invoiceTermsList[0].Id,
            picklistLibrariesList[0].Id
        );
        insert accountsList;

        // create credit checks
        List<Credit_Check__c> creditChecksList = TestDataCreator.createCreditChecks(
            1, 
            accountsList[0].Id
        );
        insert creditChecksList;
        accountsList[0].Credit_Check__c = creditChecksList[0].Id;
        update accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
		contactsList[0].Plan_Code__c = picklistLibrariesList[0].Id;
        insert contactsList;
        

		// Create a Community User linked to the contact
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :communityProfileName LIMIT 1];

        User communityUser = new User(
            Alias = 'commusr',
            Email = 'communityuser@test.com.fake',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CommunityUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'communityuser@test.com.test.fake',
            ContactId = contactsList[0].Id
        );
        insert communityUser;
	}
	@isTest
    static void testGetBranchDetailsAsCommunityUser() {
		User communityUser = [SELECT Id, ContactId FROM User WHERE Username = :communityUserName LIMIT 1];
		
        Contact contactRecordForUser = [Select Id, OwnerId, Owner.CommunityNickname, Owner.Name, Owner.Email, Owner.Phone From Contact Where Id = :communityUser.ContactId Limit 1];
        //User currentUser = [Select Id, Name, Phone, Email, CommunityNickname FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(communityUser) {
            Test.startTest();
            Map<String, String> result = ConnectPortalFAQBranchDetailsController.getBranchDetails();
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals('Test Branch', result.get('branchName'));
            //Updated test class to allow for either version of the community nickname setting.
            Boolean ownerNameMatches = contactRecordForUser.Owner.CommunityNickname == result.get('contactName') || contactRecordForUser.Owner.Name == result.get('contactName');
            System.assert(ownerNameMatches, 'There was an issue getting the owner name of the contact, expected: '+contactRecordForUser.Owner.CommunityNickname+' or '+contactRecordForUser.Owner.Name+' but got: '+result.get('contactName'));
            System.assertEquals(contactRecordForUser.Owner.Email, result.get('contactEmail'));
            System.assertEquals(contactRecordForUser.Owner.Phone, result.get('contactPhone'));
        }
	}

}