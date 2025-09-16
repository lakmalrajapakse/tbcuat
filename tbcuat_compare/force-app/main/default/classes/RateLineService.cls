public inherited sharing class RateLineService {
    public static void syncRateCodes(List<sirenum__Rate_Line__c> rateLines) {
        Set<Id> rateCodeIds = new Set<Id>();

        for (sirenum__Rate_Line__c rateLine : rateLines) {
            rateCodeIds.add(rateLine.Rate_Code__c);
        }

        Map<Id, Rate_Code__c> rateCodesById = new Map<Id, Rate_Code__c>(RateLineSelector.getRateCodesById(rateCodeIds));

        for (sirenum__Rate_Line__c rateLine : rateLines) {
            Rate_Code__c rateCode = rateCodesById.get(rateLine.Rate_Code__c);

            if (rateCode != null) {
                rateLine.sirenum__Code__c = rateCode.Name;
            }
        }
    }
}