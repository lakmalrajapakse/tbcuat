public with sharing class JobService {
    public static void syncRateCardsFromRoleByJobId(Set<Id> jobIds) {
        List<TR1__Job__c> jobs = JobSelector.getJobsByJobId(jobIds);
        Set<Job_Rate_Line__c> existingJrls = JobSelector.getJobRateLinesByJobIdForComparison(jobIds);
        Map<Id, Set<sirenum__Rate_Line__c>> rateLinesByRateCardId = getRateCardLinesByRateCardId(jobs);

        List<Job_Rate_Line__c> newJrls = new List<Job_Rate_Line__c>();

        for (TR1__Job__c job : jobs) {
            Id rateCardId = job.s5m__JobRole__r.sirenum__Rate_Card__c;
            Set<sirenum__Rate_Line__c> linesForRateCardId = rateLinesByRateCardId.get(rateCardId);

            if (rateCardId == null || linesForRateCardId == null) {
                continue;
            }

            for (sirenum__Rate_Line__c line : linesForRateCardId) {
                Job_Rate_Line__c jrl = new Job_Rate_Line__c(
                    Rate_Line__c = line.Id,
                    Rate_Card_Page__c = line.sirenum__Rate_Card_Page__c,
                    Job__c = job.Id
                );

                if (existingJrls.contains(jrl)) {
                    continue;
                }

                newJrls.add(jrl);
            }
        }

        Database.insert(newJrls, AccessLevel.USER_MODE);
    }

    private static Map<Id, Set<sirenum__Rate_Line__c>> getRateCardLinesByRateCardId(List<TR1__Job__c> jobs) {
        Map<Id, Set<sirenum__Rate_Line__c>> results = new Map<Id, Set<sirenum__Rate_Line__c>>();
        Map<Id, Id> rateCardIdsByJobId = new Map<Id, Id>();

        for (TR1__Job__c job : jobs) {
            rateCardIdsByJobId.put(job.Id, job.s5m__JobRole__r.sirenum__Rate_Card__c);
        }

        List<sirenum__Rate_Card_Page__c> rateCardPages = JobSelector.getRateCardPagesByRateCardIds(
            new Set<Id>(rateCardIdsByJobId.values())
        );

        Map<Id, Set<sirenum__Rate_Line__c>> rateLinesByRateCardId = new Map<Id, Set<sirenum__Rate_Line__c>>();

        for (sirenum__Rate_Card_Page__c rateCardPage : rateCardPages) {
            Set<sirenum__Rate_Line__c> linesForPage = rateLinesByRateCardId.get(rateCardPage.sirenum__Rate_Card__c);

            if (linesForPage == null) {
                linesForPage = new Set<sirenum__Rate_Line__c>();
                rateLinesByRateCardId.put(rateCardPage.sirenum__Rate_Card__c, linesForPage);
            }

            linesForPage.addAll(rateCardPage.sirenum__Rate_Lines__r);
        }

        return rateLinesByRateCardId;
    }
}