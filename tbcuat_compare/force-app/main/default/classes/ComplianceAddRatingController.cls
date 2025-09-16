public with sharing class ComplianceAddRatingController {
    @AuraEnabled
    public static List<RatingOption> getRatingOptions() {
        List<RatingOption> results = new List<RatingOption>();
        List<Schema.PicklistEntry> picklistEntries = ComplianceService.getRatingValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (!entry.isActive()) {
                continue;
            }

            RatingOption category = new RatingOption();
            category.label = entry.getLabel();
            category.value = entry.getValue();

            results.add(category);
        }

        return results;
    }

    @AuraEnabled
    public static void addRating(Rating rating) {
        sirenum__Ranking__c record = new sirenum__Ranking__c(
            sirenum__Contact__c = rating.contactId,
            sirenum__Rank__c = rating.rating,
            sirenum__Ranked_by__c = rating.raterId,
            sirenum__Account__c = rating.customerId
        );

        Database.insert(record, AccessLevel.USER_MODE);
    }

    public class RatingOption {
        @AuraEnabled
        public string label { get; set; }
        @AuraEnabled
        public String value { get; set; }
    }

    public class Rating {
        @AuraEnabled
        public Id contactId { get; set; }
        @AuraEnabled
        public String rating { get; set; }
        @AuraEnabled
        public Id raterId { get; set; }
        @AuraEnabled
        public Id customerId { get; set; }
    }
}