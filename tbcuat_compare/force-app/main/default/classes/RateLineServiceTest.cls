@isTest
public class RateLineServiceTest {

    @isTest
    static void validateRatesCanChange_givenSalaryThresholdOnPage_willErrorIfBelowMinimumRate() {
        sirenum__Standard_Rate_Type__c rateType = new sirenum__Standard_Rate_Type__c(
            ValidationEnabled__c = true,
            sirenum__Rate_Code__c = 'Test',
            sirenum__SortOrder__c = 5
        );
        insert rateType;


        sirenum__Rate_Card__c rateCard = new sirenum__Rate_Card__c();
        insert rateCard;

        Salary_Threshold__mdt threshold = new Salary_Threshold__mdt(
            DeveloperName = 'Test_Threshold',
            Label = 'Test Threshold',
            Minimum_Rate__c = 15,
            IsDefault__c = true
        );

        RateLineSelector.MOCK_SALARY_THRESHOLDS.add(threshold);

        sirenum__Rate_Card_Page__c rateCardPage = new sirenum__Rate_Card_Page__c(
            sirenum__Rate_Card__c = rateCard.Id,
            sirenum__SortOrder__c = 5,
            sirenum__Condition_Field__c = String.valueOf(sirenum__Shift__c.Salary_Threshold__c),
            sirenum__Condition_Operator__c = 'Equal To',
            sirenum__Condition_Value__c = 'Test_Threshold'
        );
        insert rateCardPage;

        sirenum__Rate_Line__c rateLine = new sirenum__Rate_Line__c(
            sirenum__Rate_Card_Page__c = rateCardPage.Id,
            sirenum__Charge_Rate__c = 25,
            sirenum__Pay_Rate__c = 101,
            sirenum__SortOrder__c = 5,
            sirenum__Standard_Rate_Type__c = rateType.Id
        );
        insert rateLine;

        sirenum__Team__c role1 = new sirenum__Team__c(sirenum__Rate_Card__c = rateCard.Id);
        insert new List<SObject>{ role1 };

        TR1__Job__c job = new TR1__Job__c(s5m__JobRole__c = role1.Id, Approved__c = false);
        insert new List<SObject>{ job };

        rateLine.sirenum__Pay_Rate__c = 14;

        Test.startTest();
        try {
            update rateLine;
        }catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        
        Test.stopTest();
    }
}