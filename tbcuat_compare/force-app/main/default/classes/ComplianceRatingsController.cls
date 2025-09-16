public with sharing class ComplianceRatingsController {
    @AuraEnabled
    public static List<ListRating> getRatings(Id contactId) {
        List<sirenum__Ranking__c> ratings = ComplianceService.getRatings(contactId);

        List<ListRating> results = new List<ListRating>();

        for (sirenum__Ranking__c rating : ratings) {
            ListRating dto = new ListRating();
            dto.id = rating.Id;
            dto.rating = rating.sirenum__Rank__c;
            dto.customerName = rating.sirenum__Account__r.Name;
            dto.raterName = rating.sirenum__Ranked_by__r.Name;
            dto.ratingDate = rating.CreatedDate;

            results.add(dto);
        }

        return results;
    }

    public class ListRating {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String rating { get; set; }
        @AuraEnabled
        public String customerName { get; set; }
        @AuraEnabled
        public String raterName { get; set; }
        @AuraEnabled
        public DateTime ratingDate { get; set; }
    }
}