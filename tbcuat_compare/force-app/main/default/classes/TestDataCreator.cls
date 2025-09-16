/**
* @description Apex class is used to easily create data for tests 
**/
public with sharing class TestDataCreator {

    /**
    * @description Method to create invoice terms
    **/
    public static List<InvoiceTerm__c> createInvoiceTerms(Integer noOfInvoiceTerms){
        List<InvoiceTerm__c> invoiceTermsList = new List<InvoiceTerm__c>();
        for(Integer i=0;i<noOfInvoiceTerms;i++){
            invoiceTermsList.add(new InvoiceTerm__c( 
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
                TermsTemplateName__c = 'Default Charge Terms'
            ));
        }
        return invoiceTermsList;
    }

    /**
    * @description Method to create regions
    **/
    public static List<Region__c> createRegions(Integer noOfRegions){
        List<Region__c> regionsList = new List<Region__c>();
        for(Integer i=0;i<noOfRegions;i++){
            regionsList.add(new Region__c( 
                Name = 'Test Region'
            ));
        }
        return regionsList;
    }

    /**
    * @description Method to create area
    **/
    public static List<Area__c> createAreas(Integer noOfAreas, Id regionId){
        List<Area__c> areasList = new List<Area__c>();
        for(Integer i=0;i<noOfAreas;i++){
            areasList.add(new Area__c( 
                Name = 'Test Area',
                Region__c = regionId
            ));
        }
        return areasList;
    }

    /**
    * @description Method to create branches list
    **/
    public static List<Branch__c> createBranches(Integer noOfBranches, Id areaId){
        List<Branch__c> branchesList = new List<Branch__c>();
        for(Integer i=0;i<noOfBranches;i++){
            branchesList.add(new Branch__c( 
                Name = 'Ashford',
                Area__c = areaId
            ));
        }
        return branchesList;
    }

    /**
    * @description Method to create picklist library
    **/
    public static List<Picklist_Library__c> createPicklistLibraries(Integer noOfPicklistLibraries){
        List<Picklist_Library__c> picklistLibrariesList = new List<Picklist_Library__c>();
        for(Integer i=0;i<noOfPicklistLibraries;i++){
            picklistLibrariesList.add(new Picklist_Library__c( 
                Name = 'APRG1',
                Branch_Code__c = 'Test Branch',
                Division_Code__c = 'Test Division',
                RecordTypeId = Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId()
            ));
        }
        return picklistLibrariesList;
    }

    /**
    * @description Method to create picklist library
    **/
    public static List<Picklist_Library__c> createPicklistLibraries(Integer noOfPicklistLibraries, Id branchId){
        List<Picklist_Library__c> picklistLibrariesList = new List<Picklist_Library__c>();
        for(Integer i=0;i<noOfPicklistLibraries;i++){
            picklistLibrariesList.add(new Picklist_Library__c( 
                Name = 'APRG1',
                Branch_Code__c = 'Test Branch',
                Division_Code__c = 'Test Division',
                RecordTypeId = Schema.SObjectType.Picklist_Library__c.getRecordTypeInfosByDeveloperName().get('Plan_Code').getRecordTypeId(),
                Branch__c = branchId
            ));
        }
        return picklistLibrariesList;
    }

    /**
    * @description Method to create credit checks
    **/
    public static List<Credit_Check__c> createCreditChecks(Integer noOfCreditChecks, Id accountId){
        List<Credit_Check__c> creditChecksList = new List<Credit_Check__c>();
        for(Integer i=0;i<noOfCreditChecks;i++){
            creditChecksList.add(new Credit_Check__c( 
                Client__c = accountId,
                Status__c = 'Verified Approved'
            ));
        }
        return creditChecksList;
    }
    
    /**
    * @description Method to create clients
    **/
    public static List<Account> createClients(Integer noOfClients, Id invoiceTermId, Id picklistLibraryId){
        List<Account> accountsList = new List<Account>();
        for(Integer i=0;i<noOfClients;i++){
            accountsList.add(new Account( 
                Name='Test Account - '+String.valueOf(i), 
                Industry = 'Construction',
                InvoiceTerm__c = invoiceTermId,
                Plan_Code__c = picklistLibraryId,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId(),
                TR1__Status__c = 'Credit Check',
                Client_Code__c = 'ABCL9151'
            ));
        }
        return accountsList;
    }

    /**
    * @description Method to create contact
    **/
    public static List<Contact> createContacts(Integer noOfContacts, List<Account> accountsList){
        List<Contact> contactsList = new List<Contact>();
        for(Account account : accountsList){
            for(Integer i=0;i<noOfContacts;i++){
                contactsList.add(new Contact(
                    LastName = 'Account - '+String.valueOf(i),
                    AccountId = account.Id,
                    Email = 'test@test.com',
                    Do_you_have_the_right_to_work_in_the_UK__c = true,
                    Do_you_currently_live_in_the_UK__c = true
                ));
            }
        }
        return contactsList;
    }

    /**
    * @description Method to create contact
    **/
    public static List<Bank_Details__c> createBankDetails(Integer noOfBankDetails, Id contactId){
        List<Bank_Details__c> bankDetailsList = new List<Bank_Details__c>();
        for(Integer i=0;i<noOfBankDetails;i++){
            bankDetailsList.add(new Bank_Details__c(
                Bank_Account_Number__c = '12345678',
                Bank_Name__c = 'Nationwide',
                Sort_Code__c = '12-34-56',
                Contact_Associated__c = contactId,
                Account_Holder_Name__c = 'Test'
            ));
        }
        return bankDetailsList;
    }

    /**
    * @description Method to create sites
    **/
    public static List<sirenum__Site__c> createSites(Integer noOfSites){
        List<sirenum__Site__c> sitesList = new List<sirenum__Site__c>();
        for(Integer i=0;i<noOfSites;i++){
            sitesList.add(new sirenum__Site__c(
                Name = 'Test Site'
            ));
        }
        return sitesList;
    }

    /**
    * @description Method to create contracts
    **/
    public static List<sirenum__ProActiveContract__c> createContracts(Integer noOfContracts, Id clientId){
        List<sirenum__ProActiveContract__c> contractsList = new List<sirenum__ProActiveContract__c>();
        for(Integer i=0;i<noOfContracts;i++){
            contractsList.add(new sirenum__ProActiveContract__c(
                Name = 'Test Contract',
                sirenum__Client__c = clientId
            ));
        }
        return contractsList;
    }

    /**
    * @description Method to create job roles
    **/
    public static List<sirenum__Team__c> createJobRoles(Integer noOfJobRoles, Id contractId){
        List<sirenum__Team__c> jobRolesList = new List<sirenum__Team__c>();
        for(Integer i=0;i<noOfJobRoles;i++){
            jobRolesList.add(new sirenum__Team__c(
                Name = 'ABCL9151 - Test Driver',
                sirenum__Account__c = contractId,
                sirenum__AWR_Group__c = 'Class 1 Driver'
            ));
        }
        return jobRolesList;
    }

    /**
    * @description Method to create placements
    **/
    public static List<sirenum__Placement__c> createPlacements(Integer noOfPlacements, Id contractId, Id jobRoleId, Id siteId, Id contactId){
        List<sirenum__Placement__c> placementsList = new List<sirenum__Placement__c>();
        for(Integer i=0;i<noOfPlacements;i++){
            placementsList.add(new sirenum__Placement__c(
                Name = 'Test Driver',
                sirenum__Contract__c = contractId,
                sirenum__Contact__c = contactId,
                sirenum__Job_Role__c = jobRoleId,
                sirenum__Site__c = siteId,
                sirenum__Start_Date__c = System.today(),
                sirenum__Status__c = 'Active'
            ));
        }
        return placementsList;
    }

    /**
    * @description Method to create payroll cycle
    **/
    public static List<sirenum__Payroll_Cycle__c> createPayrollCycles(Integer noOfpayrollCycles){
        List<sirenum__Payroll_Cycle__c> payrollCyclesList = new List<sirenum__Payroll_Cycle__c>();
        for(Integer i=0;i<noOfpayrollCycles;i++){
            payrollCyclesList.add(new sirenum__Payroll_Cycle__c(
                Name = 'Test Payroll Cycle',
                RSMDateCalculatorName__c = 'weekly',
                sirenum__CyclePeriodUnits__c = 'Weeks',
                sirenum__periodLength__c = 7,
                sirenum__StartingDate__c = System.today()
            ));
        }
        return payrollCyclesList;
    }

     /**
    * @description Method to create weeks
    **/
    public static List<sirenum__Week__c> createWeeks(Integer noOfWeeks, Id payrollCycleId){
        List<sirenum__Week__c> weeksList = new List<sirenum__Week__c>();
        for(Integer i=0;i<noOfWeeks;i++){
            weeksList.add(new sirenum__Week__c(
                Name = '2025-01',
                sirenum__Start_Date__c = System.today(),
                sirenum__Week_Ending__c = System.today().addDays(7),
                sirenum__PayrollCycle__c = payrollCycleId
            ));
        }
        return weeksList;
    }

    /**
    * @description Method to create timesheets
    **/
    public static List<sirenum__Timesheet__c> createTimesheets(Integer noOfTimesheets, Id accountId, Id contractId, Id weekId, Id contactId){
        List<sirenum__Timesheet__c> timesheetsList = new List<sirenum__Timesheet__c>();
        for(Integer i=0;i<noOfTimesheets;i++){
            timesheetsList.add(new sirenum__Timesheet__c(
                sirenum__Contract__c = contractId,
                sirenum__Worker__c = contactId,
                sirenum__Client__c = accountId,
                sirenum__Week__c = weekId
            ));
        }
        return timesheetsList;
    }

    /**
    * @description Method to create shits
    **/
    public static List<sirenum__Shift__c> createShifts(Integer noOfShifts, Id contractId, Id jobRoleId, Id siteId, Id contactId, Id placementId){
        List<sirenum__Shift__c> shiftsList = new List<sirenum__Shift__c>();
        for(Integer i=0;i<noOfShifts;i++){
            Date tempDate = System.today().addDays(i);
            shiftsList.add(new sirenum__Shift__c(
                sirenum__Contract__c = contractId,
                sirenum__Contact__c = contactId,
                sirenum__Placement__c = placementId,
                sirenum__Site__c = siteId,
                sirenum__Team__c = jobRoleId,
                sirenum__Scheduled_Start_Time__c = DateTime.newInstance(tempDate,Time.newInstance(9,0,0,0)),
                sirenum__Scheduled_End_Time__c = DateTime.newInstance(tempDate,Time.newInstance(17,0,0,0)),
                sirenum__Cancelled__c = false
            ));
        }
        return shiftsList;
    }

    /**
    * @description Method to create timesheet lines
    **/
    public static List<sirenum__Timesheet_Line__c> createTimesheetLines(Integer noOfTimesheetLines, Id timesheetId, Set<Id> shiftIds){
        List<sirenum__Timesheet_Line__c> timesheetLinesList = new List<sirenum__Timesheet_Line__c>();
        for(Integer i=0;i<noOfTimesheetLines;i++){
            for (Integer j=0;j<shiftIds.size();j++) {
                Date tempDate = System.today().addDays(j);
                timesheetLinesList.add(new sirenum__Timesheet_Line__c(
                    sirenum__Hours__c = 8,
                    sirenum__Rate__c = 40,
                    sirenum__Charge__c = 50,
                    sirenum__Timesheet__c = timesheetId,
                    sirenum__Shift__c = new List<Id>(shiftIds)[j],
                    sirenum__Date__c = tempDate
                ));
            }
        }
        return timesheetLinesList;
    }

     /**
    * @description Method to create expenes
    **/
    public static List<sirenum__Expense__c> createExpenses(Integer noOfExpenses, Id timesheetId){
        List<sirenum__Expense__c> expensesList = new List<sirenum__Expense__c>();
        for(Integer i=0;i<noOfExpenses;i++){
            expensesList.add(new sirenum__Expense__c(
                sirenum__Beneficiary_Name__c = 'Test',
                sirenum__Expense_number__c = 'Test',
                sirenum__Date_of_expense__c = System.today(),
                sirenum__Date_of_payment__c = System.today(),
                sirenum__Timesheet__c = timesheetId,
                sirenum__Amount__c = 50.00
            ));
        }
        return expensesList;
    }

    /**
    * @description Method to create timesheet lines
    **/
    public static List<InTimeSyncItem__c> createIntimeSyncItems(Id accountId, Id contactId, Id placementId, Id timesheetId, Id employeeRequestId){
        List<InTimeSyncItem__c> intimeSyncItemsList = new List<InTimeSyncItem__c>();
        if (accountId != null)  intimeSyncItemsList.add(new InTimeSyncItem__c(Client__c = accountId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED));
        if (contactId != null)  intimeSyncItemsList.add(new InTimeSyncItem__c(Person__c = contactId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED));
        if (placementId != null)  intimeSyncItemsList.add(new InTimeSyncItem__c(Placement__c = placementId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED));
        if (timesheetId != null)  intimeSyncItemsList.add(new InTimeSyncItem__c(Timesheet__c = timesheetId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED));
        if (employeeRequestId != null)  intimeSyncItemsList.add(new InTimeSyncItem__c(EmployeeRequest__c = employeeRequestId, Status__c = IntimeConstants.INTIME_SYNC_ITEM_STATUS_QUEUED));
        return intimeSyncItemsList;
    }

     /**
    * @description Method to create content version
    **/
    public static List<ContentVersion> createContentVersion(Integer noOfVersions){
        List<ContentVersion> contentVersionsList = new List<ContentVersion>();
        for (Integer i=0;i<noOfVersions;i++) {
            contentVersionsList.add(new ContentVersion(
                versionData = Blob.valueOf('Test'),
                Title = 'Test - '+System.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ'),
                PathOnClient = 'Test - '+System.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ')+'.pdf'
            ));
        }
        return contentVersionsList;
    }

    /**
    * @description Method to create content document link
    **/
    public static List<ContentDocumentLink> createContentDocumentLinks(Set<Id> contentVersionIds, Set<Id> parentIds){
        List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>();
        for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIds]) {
            for (Id parentId : parentIds) {
                contentDocumentLinksList.add(new ContentDocumentLink(
                    LinkedEntityId = parentId,
                    ShareType = 'V',
                    ContentDocumentId = contentVersion.ContentDocumentId
                ));
            }
        }
        return contentDocumentLinksList;
    }

    /**
    * @description Method to create employee requests
    **/
    public static List<sirenum__Employee_Request__c> createEmployeeRequests(Integer noOfEmployeeRequests, Id contactId){
        List<sirenum__Employee_Request__c> employeeRequestsList = new List<sirenum__Employee_Request__c>();
        for (Integer i=0;i<noOfEmployeeRequests;i++) {
            employeeRequestsList.add(new sirenum__Employee_Request__c(
                sirenum__Contact__c = contactId,
                sirenum__Start_Time__c = DateTime.newInstance(System.today(),Time.newInstance(9,0,0,0)),
                sirenum__End_Time__c = DateTime.newInstance(System.today(),Time.newInstance(17,0,0,0)),
                sirenum__Type__c = IntimeConstants.EMPLOYEE_REQUEST_TYPE_HOLIDAY,
                sirenum__Approved__c = true
            ));
        }
        return employeeRequestsList;
    }

    /**
    * @description Method to create rebates
    **/
    public static List<Rebate__c> createRebates(Integer numberOfRebates){
        List<Rebate__c> rebatesList = new List<Rebate__c>();
        for (Integer i=0;i<numberOfRebates;i++) {
            rebatesList.add(new Rebate__c(
                Percent__c = 10.00,
                Type__c = 'Percent',
                Name = 'Default'
            ));
        }
        return rebatesList;
    }

    /**
    * @description Method to create rate cards
    **/
    public static List<sirenum__Rate_Card__c> createRateCards(Integer numberOfRateCards){
        List<sirenum__Rate_Card__c> rateCardsList = new List<sirenum__Rate_Card__c>();
        for (Integer i=0;i<numberOfRateCards;i++) {
            rateCardsList.add(new sirenum__Rate_Card__c(
                Name = 'Default'
            ));
        }
        return rateCardsList;
    }

    /**
    * @description Method to create rate card pages
    **/
    public static List<sirenum__Rate_Card_Page__c> createRateCardPages(Integer numberOfRateCardPages, Set<Id> rateCardIds){
        List<sirenum__Rate_Card_Page__c> rateCardPagesList = new List<sirenum__Rate_Card_Page__c>();
        for (Integer i=0;i<numberOfRateCardPages;i++) {
            for (Id rateCardId : rateCardIds) {
                rateCardPagesList.add(new sirenum__Rate_Card_Page__c(
                    sirenum__Rate_Card__c = rateCardId,
                    sirenum__SortOrder__c = 1,
                    sirenum__Condition_Field__c = String.valueOf(sirenum__Shift__c.Salary_Threshold__c),
                    sirenum__Condition_Operator__c = 'Equal To',
                    sirenum__Condition_Value__c = 'Test_Threshold'
                ));
            }
        }
        return rateCardPagesList;
    }

    /**
    * @description Method to create rate codes
    **/
    public static List<Rate_Code__c> createRateCodes(Integer numberOfRateCodes){
        List<Rate_Code__c> rateCodesList = new List<Rate_Code__c>();
        for (Integer i=0;i<numberOfRateCodes;i++) {
            rateCodesList.add(new Rate_Code__c(
                Name = 'Test',
                Validation_Enabled__c = true
            ));
        }
        return rateCodesList;
    }

    /**
    * @description Method to create rate lines
    **/
    public static List<sirenum__Rate_Line__c> createRateLines(Integer numberOfRateLines, Set<Id> rateCardPageIds, Id rateCodeId){
        List<sirenum__Rate_Line__c> rateLinesList = new List<sirenum__Rate_Line__c>();
        for (Integer i=0;i<numberOfRateLines;i++) {
            for (Id rateCardPageId : rateCardPageIds) {
                rateLinesList.add(new sirenum__Rate_Line__c(
                    sirenum__Rate_Card_Page__c = rateCardPageId,
                    sirenum__Charge_Rate__c = 25,
                    sirenum__Pay_Rate__c = 20,
                    sirenum__SortOrder__c = 1,
                    Rate_Code__c = rateCodeId
                ));
            }
        }
        return rateLinesList;
    }

    /**
    * @description Method to create rate modifier types
    **/
    public static List<sirenum__Rate_Modifier_Type__c> createRateModifierTypes(Integer numberOfRateModifierTypes){
        List<sirenum__Rate_Modifier_Type__c> rateModifierTypesList = new List<sirenum__Rate_Modifier_Type__c>();
        for (Integer i=0;i<numberOfRateModifierTypes;i++) {
            rateModifierTypesList.add(new sirenum__Rate_Modifier_Type__c(
                sirenum__SortOrder__c = 1,
                sirenum__Condition_value__c = 'TRUE',
                sirenum__Condition_Field__c = 'AWR',
                sirenum__Condition_Operator__c = 'Equal To'
            ));
        }
        return rateModifierTypesList;
    }

    /**
    * @description Method to create rate modifiers 
    **/
    public static List<sirenum__Rate_Modifier__c> createRateModifiers(Integer numberOfRateModifiers, Set<Id> rateLineIds, Id rateModifierTypeId){
        List<sirenum__Rate_Modifier__c> rateModifiersList = new List<sirenum__Rate_Modifier__c>();
        for (Integer i=0;i<numberOfRateModifiers;i++) {
            for (Id rateLineId : rateLineIds) {
                rateModifiersList.add(new sirenum__Rate_Modifier__c(
                    sirenum__Charge_Rate__c = 45,
                    sirenum__Pay_Rate__c = 40,
                    sirenum__Rate_Line__c = rateLineId,
                    sirenum__Rate_Modifier_Type__c = rateModifierTypeId
                ));
            }
        }
        return rateModifiersList;
    }

    /**
    * @description Method to create standard rate types
    **/
    public static List<sirenum__Standard_Rate_Type__c> createStandardRateTypes(Integer numberOfRateTpes){
        List<sirenum__Standard_Rate_Type__c> rateTypesList = new List<sirenum__Standard_Rate_Type__c>();
        for (Integer i=0;i<numberOfRateTpes;i++) {
            rateTypesList.add(new sirenum__Standard_Rate_Type__c(
                ValidationEnabled__c = true,
                sirenum__Rate_Code__c = 'Test',
                sirenum__SortOrder__c = 5
            ));
        }
        return rateTypesList;
    }

    /**
    * @description Method to create break defintions
    **/
    public static List<sirenum__Break_definition__c> createBreakDefinitions(Integer numberOfBreakDefinitions, Id contractId){
        List<sirenum__Break_definition__c> breakDefinitionsList = new List<sirenum__Break_definition__c>();
        for (Integer i=0;i<numberOfBreakDefinitions;i++) {
            breakDefinitionsList.add(new sirenum__Break_definition__c(
                WFM_Contract__c = contractId,
                sirenum__Break_length__c = 15,
                sirenum__BreakTime__c = '09:00'
            ));
        }
        return breakDefinitionsList;
    }

    /**
    * @description Method to create candidate consents
    **/
    public static List<TR1__Candidate_Consents__c> createCandidateConsents(Integer numberOfCandidateConsents, Id contactId){
        List<TR1__Candidate_Consents__c> candidateConsentsList = new List<TR1__Candidate_Consents__c>();
        for (Integer i=0;i<numberOfCandidateConsents;i++) {
            candidateConsentsList.add(new TR1__Candidate_Consents__c(
                TR1__Candidate__c = contactId
            ));
        }
        return candidateConsentsList;
    }

    /**
    * @description Method to create candidate opt outs
    **/
    public static List<TR1__Email_Type__c> createEmailType(Integer numberOfEmailTypes){
        List<TR1__Email_Type__c> emailTypesList = new List<TR1__Email_Type__c>();
        for (Integer i=0;i<numberOfEmailTypes;i++) {
            emailTypesList.add(new TR1__Email_Type__c(
                TR1__Hide_Unsubscribe_Link__c = false
            ));
        }
        return emailTypesList;
    }

    /**
    * @description Method to create candidate opt outs
    **/
    public static List<TR1__Candidate_Opt_Out__c> createCandidateOptOuts(Integer numberOfCandidateOptOuts, Id contactId, Id emailTypeId){
        List<TR1__Candidate_Opt_Out__c> candidateOptoutsList = new List<TR1__Candidate_Opt_Out__c>();
        for (Integer i=0;i<numberOfCandidateOptOuts;i++) {
            candidateOptoutsList.add(new TR1__Candidate_Opt_Out__c(
                TR1__Candidate__c = contactId,
                TR1__Email_Type__c = emailTypeId
            ));
        }
        return candidateOptoutsList;
    }

    /**
    * @description Method to create candidate statitics
    **/
    public static List<TR1__Candidate_Summary__c> createCandidateStatistics(Integer numberOfCandidateStatistics, Id contactId){
        List<TR1__Candidate_Summary__c> candidateStatisticsList = new List<TR1__Candidate_Summary__c>();
        for (Integer i=0;i<numberOfCandidateStatistics;i++) {
            candidateStatisticsList.add(new TR1__Candidate_Summary__c(
                TR1__Contact__c = contactId
            ));
        }
        return candidateStatisticsList;
    }

    /**
    * @description Method to create chat messages
    **/
    public static List<b3o__Chat_Message__c> createChatMessages(Integer numberOfChatMessages, Id contactId){
        List<b3o__Chat_Message__c> chatMessagesList = new List<b3o__Chat_Message__c>();
        for (Integer i=0;i<numberOfChatMessages;i++) {
            chatMessagesList.add(new b3o__Chat_Message__c(
                b3o__Contact__c = contactId
            ));
        }
        return chatMessagesList;
    }

    /**
    * @description Method to create davis error logs
    **/
    public static List<Davis_Error_Log__c> createDavisErrorLog(Integer numberOfDavisErrorLogs, Id contactId){
        List<Davis_Error_Log__c> davisErrorLogsList = new List<Davis_Error_Log__c>();
        for (Integer i=0;i<numberOfDavisErrorLogs;i++) {
            davisErrorLogsList.add(new Davis_Error_Log__c(
                Driver__c = contactId,
                Date__c = System.today()
            ));
        }
        return davisErrorLogsList;
    }

    /**
    * @description Method to create deleted shifts
    **/
    public static List<sirenum__Deleted_Shift__c> createDeletedShifts(Integer numberOfDeletedShifts, Id jobRoleId, Id contactId){
        List<sirenum__Deleted_Shift__c> deletedShiftsList = new List<sirenum__Deleted_Shift__c>();
        for (Integer i=0;i<numberOfDeletedShifts;i++) {
            deletedShiftsList.add(new sirenum__Deleted_Shift__c(
                sirenum__Team__c = jobRoleId,
                sirenum__Contact__c = contactId,
                sirenum__Scheduled_Start_Time__c = DateTime.newInstance(System.today(),Time.newInstance(9,0,0,0)),
                sirenum__Scheduled_End_Time__c = DateTime.newInstance(System.today(),Time.newInstance(17,0,0,0))
            ));
        }
        return deletedShiftsList;
    }

    /**
    * @description Method to create job leads
    **/
    public static List<TR1__Job_Leads__c> createJobLeads(Integer numberOfJobLeads, Id accountId){
        List<TR1__Job_Leads__c> jobLeadsList = new List<TR1__Job_Leads__c>();
        for (Integer i=0;i<numberOfJobLeads;i++) {
            jobLeadsList.add(new TR1__Job_Leads__c(
                TR1__Account__c = accountId
            ));
        }
        return jobLeadsList;
    }

    /**
    * @description Method to create email
    **/
    public static List<TR1__EMail__c> createEmails(Integer numberOfEmails, Id jobLeadId){
        List<TR1__EMail__c> emailsList = new List<TR1__EMail__c>();
        for (Integer i=0;i<numberOfEmails;i++) {
            emailsList.add(new TR1__EMail__c(
                TR1__Job_Lead__c = jobLeadId
            ));
        }
        return emailsList;
    }

    /**
    * @description Method to create forms
    **/
    public static List<b3f__Form__c> createForms(Integer numberOfForms){
        List<b3f__Form__c> formsList = new List<b3f__Form__c>();
        for (Integer i=0;i<numberOfForms;i++) {
            formsList.add(new b3f__Form__c(
                Name = 'Test Form'
            ));
        }
        return formsList;
    }

    /**
    * @description Method to create email
    **/
    public static List<b3f__FormResponse__c> createFormResponses(Integer numberOfFormResponses, Id contactId, Id formId){
        List<b3f__FormResponse__c> formResponsesList = new List<b3f__FormResponse__c>();
        for (Integer i=0;i<numberOfFormResponses;i++) {
            formResponsesList.add(new b3f__FormResponse__c(
                b3f__Contact__c = contactId,
                b3f__Form__c = formId,
                b3f__Type__c = 'DRAFT'
            ));
        }
        return formResponsesList;
    }

    /**
    * @description Method to create email
    **/
    public static List<TR1__Job__c> createJobs(Integer numberOfJobs, Id accountId, Id picklistLibraryId){
        List<TR1__Job__c> jobsList = new List<TR1__Job__c>();
        for (Integer i=0;i<numberOfJobs;i++) {
            jobsList.add(new TR1__Job__c(
                TR1__Account__c = accountId,
                TR1__Status__c = 'Open',
                TR1__Salary_High__c = 50000,
                TR1__Fee_Percentage__c = 10,
                TR1__Estimated_Start_Date__c = System.today(),
                TR1__Estimated_End_Date__c = System.today().addDays(2),
                TR1__Division__c = 'Client Services',
                TR1__Level__c = 'Staff',
                TR1__State_Area__c = 'Alabama',
                TR1__Regional_Area__c = 'Dothan Metro Area',
                TR1__City__c = 'Test City',
                TR1__Open_Date__c = System.today(),
                Plan_Code__c = picklistLibraryId
            ));
        }
        return jobsList;
    }
}