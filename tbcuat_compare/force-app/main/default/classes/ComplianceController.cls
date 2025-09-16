public with sharing class ComplianceController {
    @AuraEnabled
    public static List<Category> getCategories() {
        List<Category> results = new List<Category>();
        List<Schema.PicklistEntry> picklistEntries = ComplianceService.getCategories();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (!entry.isActive()) {
                continue;
            }

            Category category = new Category();
            category.label = entry.getLabel();
            category.value = entry.getValue();

            results.add(category);
        }

        return results;
    }

    public class Category {
        @AuraEnabled
        public string label { get; set; }
        @AuraEnabled
        public String value { get; set; }
    }
}