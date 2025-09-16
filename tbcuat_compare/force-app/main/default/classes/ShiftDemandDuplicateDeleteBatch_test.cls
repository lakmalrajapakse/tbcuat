@isTest
public with sharing class ShiftDemandDuplicateDeleteBatch_test {
    @testSetup
    static void setUpTestData(){
        // Create Invoice Terms 
        List<InvoiceTerm__c> invoiceTermsList = TestDataCreator.createInvoiceTerms(1);
        insert invoiceTermsList;

        // Create regions
        List<Region__c> regionsList = TestDataCreator.createRegions(1);
        insert regionsList;

        // Create areas
        List<Area__c> areasList = TestDataCreator.createAreas(
            1,
            regionsList[0].Id
        );
        insert areasList;

        // Create branches
        List<Branch__c> branchesList = TestDataCreator.createBranches(
            1,
            areasList[0].Id
        );
        insert branchesList;

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(
            1,
            branchesList[0].Id
        );
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
        contactsList[0].TR1__Candidate_Status__c = 'Registered';
        insert contactsList;

        // Create sites
        List<sirenum__Site__c> sitesList = TestDataCreator.createSites(1);
        insert sitesList;

        // Create contracts
        List<sirenum__ProActiveContract__c> contractsList = TestDataCreator.createContracts(
            1,
            accountsList[0].Id
        );
        insert contractsList;

        // Create job roles
        List<sirenum__Team__c> jobRolesList = TestDataCreator.createJobRoles(
            1,
            contractsList[0].Id
        );
        insert jobRolesList;
        

        List<TR1__Job__c> jobsList = TestDataCreator.createJobs(
            1,
            accountsList[0].Id,
            picklistLibrariesList[0].Id
        );
          

        insert jobsList;

        List<sirenum__Shift__c> shiftsDemand = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            null,
            null
        );
        shiftsDemand[0].s5m__BH4SFJob__c = jobsList[0].Id;
        insert shiftsDemand;

        List<sirenum__Shift__c> shiftsList = TestDataCreator.createShifts(
            1,
            contractsList[0].Id,
            jobRolesList[0].Id,
            sitesList[0].Id,
            contactsList[0].Id,
            null
        );
        shiftsList[0].sirenum__ShiftDemand__c = shiftsDemand[0].Id;      
        shiftsList[0].s5m__BH4SFJob__c = jobsList[0].Id;
        insert shiftsList;       
    }

    @isTest
    static void testBatch() {
        List<sirenum__Shift__c> shiftsList = [SELECT Id, Name FROM sirenum__Shift__c];
        System.assertEquals(2, shiftsList.size());
        
        Test.startTest();
           ShiftDemandDuplicateDeleteBatch s = new   ShiftDemandDuplicateDeleteBatch(DateTime.now().addDays(-1), '', true);
           Database.executeBatch(s);
        Test.stopTest();

        List<sirenum__Shift__c> shiftsListAfter = [SELECT Id, Name FROM sirenum__Shift__c];
        System.assertEquals(0, shiftsListAfter.size());
    }
}