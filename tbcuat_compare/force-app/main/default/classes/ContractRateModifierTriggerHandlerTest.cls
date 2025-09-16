/**
* @description Test class for Contract Rate Modifier
**/
@isTest(seeAllData=false)
private with sharing class ContractRateModifierTriggerHandlerTest {
    
    /**
    *   @description : set up test data
    **/
    @testSetup
    static void setUpTestData(){

        // create rebates
        List<Rebate__c> rebatesList = TestDataCreator.createRebates(1);
        rebatesList[0].Type__c = 'Calculated';
        rebatesList[0].Handler__c = 'RebateCalculationHandler';
        insert rebatesList;

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
        accountsList[0].Rebate__c = rebatesList[0].Id;
        insert accountsList;

        // create contacts 
        List<Contact> contactsList =  TestDataCreator.createContacts(
            1,
            accountsList
        );
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
        accountsList = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        jobRolesList[0].Name = accountsList[0].Client_Code__c+' - Test Driver';
        insert jobRolesList;

        // create rate cards
        List<sirenum__Rate_Card__c> rateCardsList = TestDataCreator.createRateCards(
            1
        );      
        rateCardsList[0].sirenum__Account__c = accountsList[0].Id;
        insert rateCardsList;
        contractsList[0].sirenum__Rate_Card__c = rateCardsList[0].Id;
        update contractsList;

        // create rate card pages
        List<sirenum__Rate_Card_Page__c> rateCardPagesList = TestDataCreator.createRateCardPages(
            1,
            new Map<Id,sirenum__Rate_Card__c>(rateCardsList).keySet() 
        );
        rateCardPagesList[0].sirenum__Condition_Field__c = 'Job_Role_Name__c';
        rateCardPagesList[0].sirenum__Condition_Operator__c = 'Equal To';
        rateCardPagesList[0].sirenum__Condition_Value__c = 'Job Role Test_Threshold';
        insert rateCardPagesList;        

        // create rate card lines
        List<sirenum__Rate_Line__c> rateLinesList = TestDataCreator.createRateLines(
            1,
            new Map<Id,sirenum__Rate_Card_Page__c>(rateCardPagesList).keySet(),
            null
        );
        insert rateLinesList;        

        // create rate modifier types
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = TestDataCreator.createRateModifierTypes(
            1
        );
        insert rateModifierTypesList;

        // create rate modifiers 
        List<sirenum__Rate_Modifier__c> rateModifiersList = TestDataCreator.createRateModifiers(
            1,
            new Map<Id,sirenum__Rate_Line__c>(rateLinesList).keySet(),
            rateModifierTypesList[0].Id
        );
        insert rateModifiersList;
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpate(){
        Test.startTest();   
        List<ContractRateModifier__c> contractRateModifiersList = [SELECT Id FROM ContractRateModifier__c LIMIT 1];
        update contractRateModifiersList;
        Test.stopTest();
        Assert.areEqual(2,[SELECT COUNT() FROM ContractRateModifier__Share WHERE ParentId =: contractRateModifiersList[0].Id AND RowCause = 'PlanCode__c']);
    }
}