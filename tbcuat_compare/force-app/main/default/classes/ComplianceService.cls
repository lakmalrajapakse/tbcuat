public inherited sharing class ComplianceService {
    static final List<Schema.PicklistEntry> CATEGORY_ENTRIES = sirenum__TicketType__c.Competency_Category__c.getDescribe()
        .getPicklistValues();
    static final List<Schema.PicklistEntry> RATING_VALUE_ENTRIES = sirenum__Ranking__c.sirenum__Rank__c.getDescribe()
        .getPicklistValues();

    public static List<Schema.PicklistEntry> getCategories() {
        return CATEGORY_ENTRIES;
    }

    public static List<Schema.PicklistEntry> getRatingValues() {
        return RATING_VALUE_ENTRIES;
    }

    public static List<sirenum__TicketType__c> getCompetencies(List<String> categories) {
        List<sirenum__TicketType__c> records = [
            SELECT Id, Name, Competency_Category__c, sirenum__Requires_Proof__c, sirenum__Expires__c
            FROM sirenum__TicketType__c
            WHERE Competency_Category__c IN :categories
            WITH USER_MODE
            ORDER BY Name ASC
        ];

        return records;
    }

    public static List<sirenum__Ticket__c> getQualifications(Id contactId, List<String> categories) {
        List<sirenum__Ticket__c> records = [
            SELECT Id, sirenum__Valid_from__c, sirenum__Valid_until__c, sirenum__TicketType__r.Name, sirenum__Valid__c
            FROM sirenum__Ticket__c
            WHERE sirenum__TicketType__r.Competency_Category__c IN :categories AND sirenum__Owner__c = :contactId
            WITH USER_MODE
            ORDER BY sirenum__Valid_until__c ASC NULLS LAST
        ];

        return records;
    }

    public static List<sirenum__Ranking__c> getRatings(Id contactId) {
        List<sirenum__Ranking__c> records = [
            SELECT Id, sirenum__Contact__c, sirenum__Rank__c, sirenum__Ranked_by__c, sirenum__Account__c, sirenum__Ranked_by__r.Name, sirenum__Account__r.Name, CreatedDate
            FROM sirenum__Ranking__c
            WHERE sirenum__Contact__c = :contactId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];

        return records;
    }

    public static List<ContentDocumentLink> getQualificationAttachments(Set<Id> qualificationIds) {
        List<ContentDocumentLink> records = [
            SELECT Id, ContentDocument.Title, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :qualificationIds
            WITH USER_MODE
        ];

        return records;
    }
}