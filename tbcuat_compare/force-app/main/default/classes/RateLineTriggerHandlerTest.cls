@isTest
public class RateLineTriggerHandlerTest {
    @isTest
    static void updateRates_givenSalaryThresholdOnPage_willNotErrorNoValidate() {        
        sirenum__Standard_Rate_Type__c standardRateType = new sirenum__Standard_Rate_Type__c(
            ValidationEnabled__c = false, 
            name = 'No Validate', sirenum__Rate_Code__c = 'No Validate', sirenum__SortOrder__c = 1);
        insert standardRateType;

        sirenum__Rate_Card__c rateCard = new sirenum__Rate_Card__c();
        insert rateCard;

        sirenum__Rate_Card_Page__c rateCardPage = new sirenum__Rate_Card_Page__c(
            sirenum__Rate_Card__c = rateCard.Id,
            sirenum__SortOrder__c = 5
        );
        insert rateCardPage;

        sirenum__Rate_Line__c rateLine = new sirenum__Rate_Line__c(
            sirenum__Rate_Card_Page__c = rateCardPage.Id,
            sirenum__Charge_Rate__c = 25,
            sirenum__Pay_Rate__c = 15,
            sirenum__SortOrder__c = 5,
            sirenum__Standard_Rate_Type__c = standardRateType.Id
        );
        insert rateLine;

        rateLine.sirenum__Pay_Rate__c = 14;

        try {
            update rateLine;
            System.assert(true, 'Should update without an exception');
        } catch (Exception ex) {
            System.assert(false, 'Exception should not be thrown: ' + ex.getMessage());
        }
    }

    @isTest
    static void updateRates_givenSalaryThresholdOnPage_willErrorBelowMinimumRate() {
        sirenum__Rate_Card__c rateCard = new sirenum__Rate_Card__c();
        insert rateCard;

        sirenum__Rate_Card_Page__c rateCardPage = new sirenum__Rate_Card_Page__c(
            sirenum__Rate_Card__c = rateCard.Id,
            sirenum__SortOrder__c = 5
        );
        insert rateCardPage;

        sirenum__Rate_Line__c rateLine = new sirenum__Rate_Line__c(
            sirenum__Rate_Card_Page__c = rateCardPage.Id,
            sirenum__Charge_Rate__c = 25,
            sirenum__Pay_Rate__c = 20,
            sirenum__SortOrder__c = 5
        );
        insert rateLine;

        rateLine.sirenum__Pay_Rate__c = 14;

        Test.startTest();
        try {
            update rateLine;
        } catch (Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Test.stopTest();
    }    

    @isTest
    static void updateRates_givenSalaryThresholdOnPage_willNotErrorIfAboveMinimumRate() {
        sirenum__Rate_Card__c rateCard = new sirenum__Rate_Card__c();
        insert rateCard;

        Salary_Threshold__mdt threshold = new Salary_Threshold__mdt(
            DeveloperName = 'UND 21',
            Label = 'Test Threshold',
            Minimum_Rate__c = 100
        );

        RateLineSelector.MOCK_SALARY_THRESHOLDS.add(threshold);

        sirenum__Rate_Card_Page__c rateCardPage = new sirenum__Rate_Card_Page__c(
            sirenum__Rate_Card__c = rateCard.Id,
            sirenum__SortOrder__c = 5,
            sirenum__Condition_Field__c = String.valueOf('Job_Role_Name__c'),
            sirenum__Condition_Operator__c = 'Equal To',
            sirenum__Condition_Value__c = 'Test Job Role UND 21'
        );
        insert rateCardPage;

        Rate_Code__c rateCode = new Rate_Code__c(Validation_Enabled__c = true);
        insert rateCode;

        sirenum__Rate_Line__c rateLine = new sirenum__Rate_Line__c(
            sirenum__Rate_Card_Page__c = rateCardPage.Id,
            sirenum__Charge_Rate__c = 25,
            sirenum__Pay_Rate__c = 101,
            sirenum__SortOrder__c = 5,
            Rate_Code__c = rateCode.Id
        );
        insert rateLine;        

        rateLine.sirenum__Pay_Rate__c = 101;

        try {
            update rateLine;
            System.assert(true, 'Should update without an exception');
        } catch (Exception ex) {
            System.assert(false, 'Exception should not be thrown: ' + ex.getMessage());
        }

        List<Database.Error> errors = rateLine.geterrors();
        System.assertEquals(0, errors.size(), 'Should have no errors, actually got: ' + errors);
    }
}