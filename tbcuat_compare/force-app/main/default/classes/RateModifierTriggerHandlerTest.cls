/**
* @description Test class for RateModifierTriggerHandler
**/
@isTest(seeAllData=false)
private with sharing class RateModifierTriggerHandlerTest {
    
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

        // Create Picklist Libraries
        List<Picklist_Library__c> picklistLibrariesList = TestDataCreator.createPicklistLibraries(1);
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
        jobRolesList[0].sirenum__AWR_Group__c= sirenum__Team__c.sirenum__AWR_Group__c.getDescribe().getPicklistValues().get(0).getValue();        
        insert jobRolesList;

        // create rate cards
        List<sirenum__Rate_Card__c> rateCardsList = TestDataCreator.createRateCards(
            1
        );        
        insert rateCardsList;

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
    }

    /**
    *   @description : Test After Insert
    **/
    @isTest
    static void test_afterInsert_Failure(){
        Test.startTest();   
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = [SELECT Id, Name FROM sirenum__Rate_Modifier_Type__c LIMIT 1];
        
        // create standard rate types
        List<sirenum__Standard_Rate_Type__c> rateTypesList = TestDataCreator.createStandardRateTypes(
            1
        );
        rateTypesList[0].ValidationEnabled__c = true;
        insert rateTypesList;   
        
        List<sirenum__Rate_Line__c> rateLinesList  = [SELECT Id, Name FROM sirenum__Rate_Line__c LIMIT 1];
        rateLinesList[0].sirenum__Standard_Rate_Type__c = rateTypesList[0].Id;
        update rateLinesList;

        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
        // create rate modifiers 
        List<sirenum__Rate_Modifier__c> rateModifiersList = TestDataCreator.createRateModifiers(
            1,
            new Map<Id,sirenum__Rate_Line__c>(rateLinesList).keySet(),
            rateModifierTypesList[0].Id
        );
        rateModifiersList[0].sirenum__Pay_Rate__c = 15.00;
        try {
            insert rateModifiersList;
        }catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
    }

    /**
    *   @description : Test After Insert
    **/
    @isTest
    static void test_afterInsert_Success(){
        // create standard rate types
        List<sirenum__Standard_Rate_Type__c> rateTypesList = TestDataCreator.createStandardRateTypes(
            1
        );
        rateTypesList[0].ValidationEnabled__c = false;
        insert rateTypesList;
        
        List<sirenum__Rate_Line__c> rateLinesList  = [SELECT Id, Name FROM sirenum__Rate_Line__c LIMIT 1];
        rateLinesList[0].sirenum__Standard_Rate_Type__c = rateTypesList[0].Id;
        update rateLinesList;

        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = [SELECT Id, Name FROM sirenum__Rate_Modifier_Type__c LIMIT 1];        
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);

        
        Test.startTest();   
        // create rate modifiers 
        List<sirenum__Rate_Modifier__c> rateModifiersList = TestDataCreator.createRateModifiers(
            1,
            new Map<Id,sirenum__Rate_Line__c>(rateLinesList).keySet(),
            rateModifierTypesList[0].Id
        );
        insert rateModifiersList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpdate_Failure(){
        // create standard rate types
        List<sirenum__Standard_Rate_Type__c> rateTypesList = TestDataCreator.createStandardRateTypes(
            1
        );
        rateTypesList[0].ValidationEnabled__c = true;
        insert rateTypesList;
        
        List<sirenum__Rate_Line__c> rateLinesList  = [SELECT Id, Name FROM sirenum__Rate_Line__c LIMIT 1];
        rateLinesList[0].sirenum__Standard_Rate_Type__c = rateTypesList[0].Id;
        update rateLinesList;


        
        Test.startTest();   
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = [SELECT Id, Name FROM sirenum__Rate_Modifier_Type__c LIMIT 1];                        
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
        // create rate modifiers 
        List<sirenum__Rate_Modifier__c> rateModifiersList = TestDataCreator.createRateModifiers(
            1,
            new Map<Id,sirenum__Rate_Line__c>(rateLinesList).keySet(),
            rateModifierTypesList[0].Id
        ); 
        rateModifiersList[0].sirenum__Pay_Rate__c = 103.00;
        insert rateModifiersList;
        rateModifiersList[0].sirenum__Pay_Rate__c = 90.00;
        try {
            update rateModifiersList;
        }catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
    }

    /**
    *   @description : Test After Update
    **/
    @isTest
    static void test_afterUpdate_Success(){
        // create standard rate types
        List<sirenum__Standard_Rate_Type__c> rateTypesList = TestDataCreator.createStandardRateTypes(
            1
        );
        rateTypesList[0].ValidationEnabled__c = true;
        insert rateTypesList;
        
        List<sirenum__Rate_Line__c> rateLinesList  = [SELECT Id, Name FROM sirenum__Rate_Line__c LIMIT 1];
        rateLinesList[0].sirenum__Standard_Rate_Type__c = rateTypesList[0].Id;
        update rateLinesList;

        Test.startTest();   
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = [SELECT Id, Name FROM sirenum__Rate_Modifier_Type__c LIMIT 1];        
        Assert.areEqual(0,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
        // create rate modifiers 
        List<sirenum__Rate_Modifier__c> rateModifiersList = TestDataCreator.createRateModifiers(
            1,
            new Map<Id,sirenum__Rate_Line__c>(rateLinesList).keySet(),
            rateModifierTypesList[0].Id
        );
        insert rateModifiersList;
        rateModifiersList[0].sirenum__Pay_Rate__c = 50.00;
        update rateModifiersList;
        Test.stopTest();
        Assert.areEqual(1,[SELECT COUNT() FROM sirenum__Rate_Modifier__c]);
    }
}