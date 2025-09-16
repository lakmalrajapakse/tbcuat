@isTest
public with sharing class SyncRateCardsFromJobRoleInvocableTest {
    @isTest
    static void givenJobWithRoleAndRateCard_whenNoExistingJobRateLines_thenJobRateLinesCreatedForJob() {
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
            sirenum__SortOrder__c = 5
        );
        insert rateLine;

        sirenum__Team__c role = new sirenum__Team__c(sirenum__Rate_Card__c = rateCard.Id);
        insert role;

        TR1__Job__c job = new TR1__Job__c(s5m__JobRole__c = role.Id);
        TR1__Job__c job2 = new TR1__Job__c(s5m__JobRole__c = role.Id);
        insert new List<SObject>{ job, job2 };

        Test.startTest();
        SyncRateCardsFromJobRoleInvocable.execute(new List<Id>{ job.Id });
        Test.stopTest();

        List<Job_Rate_Line__c> results = [SELECT Id, Rate_Card_Page__c, Rate_Line__c, Job__c FROM Job_Rate_Line__c];

        System.assertEquals(1, results.size(), 'Should have inserted correct number of Job Rate Lines');

        {
            Job_Rate_Line__c jrl = results.get(0);
            System.assertEquals(
                rateCardPage.Id,
                jrl.Rate_Card_Page__c,
                'Job Rate Line should have correct Rate Card Page Id'
            );
            System.assertEquals(rateLine.Id, jrl.Rate_Line__c, 'Job Rate Line should have correct Rate Line Id');
            System.assertEquals(job.Id, jrl.Job__c, 'Job Rate Line should have correct Job Id');
        }
    }

    @isTest
    static void givenJobWithRoleAndRateCard_whenExistingJobRateLinesForSameJob_thenDoesNotCreateExtraRateLine() {
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
            sirenum__SortOrder__c = 5
        );
        insert rateLine;

        sirenum__Team__c role = new sirenum__Team__c(sirenum__Rate_Card__c = rateCard.Id);
        insert role;

        TR1__Job__c job = new TR1__Job__c(s5m__JobRole__c = role.Id);
        TR1__Job__c job2 = new TR1__Job__c(s5m__JobRole__c = role.Id);
        insert new List<SObject>{ job, job2 };

        Job_Rate_Line__c existingJrl = new Job_Rate_Line__c(
            Job__c = job.Id,
            Rate_Card_Page__c = rateCardPage.Id,
            Rate_Line__c = rateLine.id
        );

        insert existingJrl;

        Test.startTest();
        SyncRateCardsFromJobRoleInvocable.execute(new List<Id>{ job.Id });
        Test.stopTest();

        List<Job_Rate_Line__c> results = [SELECT Id, Rate_Card_Page__c, Rate_Line__c, Job__c FROM Job_Rate_Line__c];

        System.assertEquals(1, results.size(), 'Should have inserted correct number of Job Rate Lines');

        {
            Job_Rate_Line__c jrl = results.get(0);
            System.assertEquals(
                rateCardPage.Id,
                jrl.Rate_Card_Page__c,
                'Job Rate Line should have correct Rate Card Page Id'
            );
            System.assertEquals(rateLine.Id, jrl.Rate_Line__c, 'Job Rate Line should have correct Rate Line Id');
            System.assertEquals(job.Id, jrl.Job__c, 'Job Rate Line should have correct Job Id');
        }
    }
}