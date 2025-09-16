@isTest
public class SetPlanCodeOnContactTest {
    
    @isTest
    static void testTriggerInsert() {
        Picklist_Library__c planCode = new Picklist_Library__c( 
            Name = 'APRG1',
            Branch_Code__c = 'Test Branch',
            Division_Code__c = 'Test Division',
            RecordTypeId = Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId());
        
        insert planCode;
        
        InvoiceTerm__c invoiceTerm = new InvoiceTerm__c( 
            Name = 'Default Charge Terms',
            Consolidation__c = 'Each Order All Plans',
            Grouping__c = 'Standard',
            InvoiceDeliveryMethod__c = '1',
            InvoiceRequiresPO__c = false,
            PaperOnInvoices__c = '0',
            SelfBilling__c = true,
            TermDays__c = 30.00,
            TermsExtraText__c = 'Test',
            TimesheetsOnInvoices__c = '0',
            TermsType__c = 'As Per Agreed Terms and Conditions',
            TermsTemplateName__c = 'Default Charge Terms');
        
        Account a = new Account( 
            Name='Test Account - 1', 
            Industry = 'Construction',
            InvoiceTerm__c = invoiceTerm.Id,
            Plan_Code__c = planCode.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId(),
            TR1__Status__c = 'Credit Check',
            Client_Code__c = 'ABCL9151');
        
        Contact c = new Contact(
            Do_you_have_the_right_to_work_in_the_UK__c = true,
            Do_you_currently_live_in_the_UK__c = true,
            LastName = 'Account - 1',
            AccountId = a.Id,
            Email = 'test@test.com',
        	ownerId = userinfo.getUserId());
        insert c;
        
        // Create and insert a TR1__Job__c record
        TR1__Job__c job = new TR1__Job__c(
            Plan_Code__c = planCode.Id,
            ownerId = userinfo.getUserId(),
            TR1__Contact__c = c.Id,
            Name = 'Test Dev',
            RecordTypeId = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get('Permanent').getRecordTypeId(),
            TR1__Account__c = a.Id,
            TR1__Most_Advanced_Stage__c = null,
            TR1__Status__c = 'Open',
            TR1__Fee_Percentage__c = 10
        );
        insert job;
    }
    
    @isTest
    static void testTriggerUpdate() {        
        Picklist_Library__c planCode = new Picklist_Library__c( 
            Name = 'APRG1',
            Branch_Code__c = 'Test Branch',
            Division_Code__c = 'Test Division',
            RecordTypeId = Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId());
        
        insert planCode;
        
        InvoiceTerm__c invoiceTerm = new InvoiceTerm__c( 
            Name = 'Default Charge Terms',
            Consolidation__c = 'Each Order All Plans',
            Grouping__c = 'Standard',
            InvoiceDeliveryMethod__c = '1',
            InvoiceRequiresPO__c = false,
            PaperOnInvoices__c = '0',
            SelfBilling__c = true,
            TermDays__c = 30.00,
            TermsExtraText__c = 'Test',
            TimesheetsOnInvoices__c = '0',
            TermsType__c = 'As Per Agreed Terms and Conditions',
            TermsTemplateName__c = 'Default Charge Terms');
        
        Account a = new Account( 
            Name='Test Account - 1', 
            Industry = 'Construction',
            InvoiceTerm__c = invoiceTerm.Id,
            Plan_Code__c = planCode.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId(),
            TR1__Status__c = 'Credit Check',
            Client_Code__c = 'ABCL9151');
        
        Contact c = new Contact(
            Do_you_have_the_right_to_work_in_the_UK__c = true,
            Do_you_currently_live_in_the_UK__c = true,
            LastName = 'Account - 1',
            AccountId = a.Id,
            Email = 'test@test.com');
        insert c;
        
        c.LastName = 'Updated';
        update c;
    }
}