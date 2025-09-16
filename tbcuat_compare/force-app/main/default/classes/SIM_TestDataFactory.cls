@isTest
public with sharing class SIM_TestDataFactory {
    public static final String ACCOUNT_CUSTOMER_RT = 'Client';
    /**
    * @description Generates test account records for a given record type

    * @author Zach Palmer | 01-25-2022 
    * @param String accountName - Name of new account
    * @param String rt - record type developer name
    * @param Boolean comit - weather or not to insert the record in the db
    * @return Account - new account
    **/
    public static Account genTestAccount(String accountName, Boolean comit) {
        Account testAccount = new Account();
        testAccount.Name = accountName;
        //testAccount.tc9_pr__Available_Payment_Methods__c = Account.tc9_pr__Available_Payment_Methods__c.getDescribe().getPicklistValues().get(0).getValue();
        //testAccount.tc9_pr__Maximum_Payment_Distributions__c = Account.tc9_pr__Maximum_Payment_Distributions__c.getDescribe().getPicklistValues().get(0).getValue();
        testAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        if(comit){
            insert testAccount;
        }
        return testAccount;

    }

    public static Account genTestAccount(String accountName, String rt, Boolean comit) {
        //Retrieve Account RecordType
        Id accountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get((String.isNotBlank(rt) ? rt : ACCOUNT_CUSTOMER_RT)).getRecordTypeId();

        //Generate Test Account
        return genTestAccount(accountName, accountRT, comit);
    }
    public static Account genTestAccount(String name, Id rtId, Boolean comit) {
        Account testAccount = new Account();

        testAccount.Name = name;
        testAccount.RecordTypeId = rtId;
        //testAccount.tc9_pr__Available_Payment_Methods__c = Account.tc9_pr__Available_Payment_Methods__c.getDescribe().getPicklistValues().get(0).getValue();
        //testAccount.tc9_pr__Maximum_Payment_Distributions__c = Account.tc9_pr__Maximum_Payment_Distributions__c.getDescribe().getPicklistValues().get(0).getValue();

        if(comit){
            insert testAccount;
        }
        return testAccount;
    }

    /**
    * @description Generates a Sirenum Site for a given Account
    * @author Zach Palmer | 01-25-2022 
    * @param Account acc - Account to attach the new Site to 
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Site__c - new Sirenum Site
    **/
    public static sirenum__Site__c genTestSite(Account acc, Boolean comit){
        sirenum__Site__c site = new sirenum__Site__c (
                sirenum__Operating_Company__r = acc,
                sirenum__Operating_Company__c = acc.Id
        );

        if(comit){
            insert site;
        }

        return site;
    }

    public static Contact genTestContact(
        String lastName,
        Id accId,
        Boolean comit
    ) {
        Contact con = new Contact();
        con.accountId = accId;
        con.LastName = lastName;
        con.Email = lastName + '@mail.com';
        if (comit)
            insert con;
        return con;
    }
    
    public static sirenum__ProActiveContract__c genTestContract(Account acc, Boolean comit){
        sirenum__ProActiveContract__c contract = new sirenum__ProActiveContract__c(
                sirenum__Client__r = acc,
                sirenum__Client__c = acc.Id
        );

        if (comit) {
            insert contract;
        }

        return contract;
    }

    /**
    * @description Generates a test contract for a given Account
    * @author Zach Palmer | 01-25-2022 
    * @param Account acc - account to relate the contract to 
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__ProActiveContract__c - new contract
    **/
    public static sirenum__ProActiveContract__c genTestContract(Account acc, Contact con, Account invAcc, Boolean comit){
        sirenum__ProActiveContract__c newContract = new sirenum__ProActiveContract__c(
                sirenum__Client__r = acc,
                sirenum__Client__c = acc.Id,
                sirenum__Account_Manager__c = con.Id
        );
        if(comit){
            insert newContract;
        }
        return newContract;
    }

    /**
    * @description Generates a new Sirenum Job Role for a given Sirenum Contract
    * @author Zach Palmer | 01-25-2022 
    * @param sirenum__ProActiveContract__c contract - Sirenum contract to attach the job role to
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Team__c - new Sirenum Job Role
    **/
    public static sirenum__Team__c genTestJobRole(sirenum__ProActiveContract__c contract, Boolean comit){
        sirenum__Team__c jobRole = new sirenum__Team__c(
                Name = 'Job Role',
                sirenum__Account__r = contract,
                sirenum__Account__c = contract.Id
        );

        if(comit){
            insert jobRole;
        }

        return jobRole;
    }
    
    public static sirenum__Placement__c genTestPlacement(Contact candidate, 
    sirenum__ProActiveContract__c contract,
    sirenum__Team__c jobRole,  Boolean comit){
        sirenum__Placement__c placement = new sirenum__Placement__c(
            sirenum__Contact__c = candidate.Id,
            sirenum__Contract__c = contract.Id,
            sirenum__Job_Role__c = jobRole.Id,
            sirenum__Start_Date__c = system.today().addDays(-365)
        );

        if(comit)
            insert placement;

        return placement;
    }
    
    public static sirenum__Payroll_Cycle__c getTestCycle(String cycleName){
        return new sirenum__Payroll_Cycle__c(
                sirenum__periodLength__c = 7,
                sirenum__StartingDate__c = system.today().toStartOfWeek(),
                sirenum__CyclePeriodUnits__c = 'Weeks',
                Name = cycleName
        );
    }

    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate){
        return getTestPeriod(cycleId, startDate, 7);
    }
    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate, Integer daysLong){
        return getTestPeriod(cycleId, startDate, startDate.addDays(daysLong));
    }
    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate, Date emdDate){
        return new sirenum__Week__c(
                sirenum__PayrollCycle__c = cycleId,
                sirenum__Start_Date__c = startDate,
                sirenum__Week_Ending__c = emdDate,
                Name = startDate.format() + ' - ' + emdDate.format());
    }

    public static User genTestUser(
        String lastName,
        String email,
        String alias,
        Id profileId,
        Boolean comit
    ) {
        User newUser = new User();
        newUser.LastName = lastName;
        newUser.Email = email;
        newUser.Alias = alias;
        newUser.Username = email + '.test.invalid';
        newUser.TimeZoneSidKey = 'America/New_York';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.ProfileId = profileId;

        if (comit)
            insert newUser;
        return newUser;
    }

    // public static Message__c genTestMessage(Boolean comit) {
    //     Message__c newMessage = new Message__c();
    //     newMessage.Body__c = 'Test';
    //     newMessage.Received_By__c = '12341234';
    //     newMessage.Sent_By__c = '43214321';

    //     if (comit) {
    //         insert newMessage;
    //     }
    //     return newMessage;
    // }

    // public static SMS_Integration_Settings__c genSMSIntegrationSettings(
    //     Boolean comit
    // ) {
    //     SMS_Integration_Settings__c settings = new SMS_Integration_Settings__c();
    //     settings.Client_Secret__c = 'Secret';
    //     settings.Default_Country_Code__c = '+44';
    //     settings.Phone_Number__c = '12341234123';
    //     settings.Provider__c = 'Twilio';
    //     settings.Username__c = 'Username';
    //     settings.Provider_Class__c = 'SMS_Twilio';

    //     if (comit) {
    //         insert settings;
    //     }

    //     return settings;
    // }

    public static sirenum__Shift__c genPastShift(Contact con, sirenum__Site__c site, sirenum__Placement__c placement, sirenum__ProActiveContract__c contract, String recType, Boolean comit) {
        // Id shiftRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Contact__c = con.Id,
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(1,0,0,0)),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(11,0,0,0)),
            sirenum__Actual_Start_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(1,0,0,0)),
            sirenum__Actual_End_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(11,0,0,0)),
            sirenum__Site__c = site.Id,
            sirenum__Placement__c = placement.Id,
            sirenum__Contract__c = contract.Id
        );

        if (comit) {
            insert shift;
        }

        return shift;
    }

    public static sirenum__Shift__c genFutureShift(Contact con, sirenum__Site__c site, sirenum__Placement__c placement, sirenum__ProActiveContract__c contract, String recType, Boolean comit) {
        // Id shiftRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Contact__c = con.Id,
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(1,0,0,0)),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(11,0,0,0)),
            sirenum__Actual_Start_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(1,0,0,0)),
            sirenum__Actual_End_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(11,0,0,0)),
            sirenum__Site__c = site.Id,
            sirenum__Placement__c = placement.Id,
            sirenum__Contract__c = contract.Id
        );

        if (comit) {
            insert shift;
        }

        return shift;
    }

    public static SIM_Response.Response deserializeSIMResponse(String jsonString, Type successRespObj, Type errorRespObj){
        if (String.isEmpty(jsonString))
           return null;
        
        Boolean success = null;        
        String message = null;
        Object responseObject = null;

        JSONParser parser = JSON.createParser(jsonString);
        while (true) {
            JSONToken t = parser.nextToken();
            if (t == null) 
                break;
            
            if (t == JSONToken.FIELD_NAME) {
                String fieldName = parser.getCurrentName();
                t = parser.nextValue();                
                
                if ('success'.equals(fieldName)) {
                   success = parser.getBooleanValue();                   
                } else if ('responseObject'.equals(fieldName)) {
                    if (success && successRespObj != null && t == JSONToken.START_OBJECT)
                        responseObject = parser.readValueAs(successRespObj);
                    else if (!success && errorRespObj != null && t == JSONToken.START_OBJECT)
                        responseObject = parser.readValueAs(errorRespObj);
                } else if ('message'.equals(fieldName)) {
                    message = parser.getText();
                }
            }
        }

        if (success == null) {
            throw new StringException('success field not populated in response');
        }

        if (success) 
            return new SIM_Response.SuccessResponse(responseObject, message) ;
        else
            return new SIM_Response.ErrorResponse(responseObject, message) ;
    }
}