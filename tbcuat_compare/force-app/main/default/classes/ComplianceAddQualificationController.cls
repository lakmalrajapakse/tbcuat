public with sharing class ComplianceAddQualificationController {
    @AuraEnabled
    public static List<Competency> getCompetencies(List<String> categories) {
        List<sirenum__TicketType__c> competencies = ComplianceService.getCompetencies(categories);
        List<Competency> results = new List<Competency>();

        for (sirenum__TicketType__c comp : competencies) {
            Competency dto = new Competency();
            dto.id = comp.Id;
            dto.name = comp.Name;
            dto.category = comp.Competency_Category__c;
            dto.canExpire = comp.sirenum__Expires__c;
            dto.requiresProof = comp.sirenum__Requires_Proof__c;
            results.add(dto);
        }

        return results;
    }

    @AuraEnabled
    public static void addQualification(Qualification qualification) {
        sirenum__Ticket__c record = new sirenum__Ticket__c(
            sirenum__TicketType__c = qualification.competencyId,
            sirenum__Owner__c = qualification.contactId,
            sirenum__Valid_from__c = qualification.validFrom,
            sirenum__Valid_until__c = qualification.validTo
        );

        Database.insert(record, AccessLevel.USER_MODE);

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (Id attachmentId : qualification.attachmentIds) {
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = attachmentId;
            contentDocumentLink.LinkedEntityId = record.id;
            contentDocumentLink.ShareType = 'I';
            contentDocumentLink.Visibility = 'AllUsers';
            contentDocumentLinks.add(contentDocumentLink);
        }

        Database.insert(contentDocumentLinks, AccessLevel.USER_MODE);
    }

    public class Competency {
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String category { get; set; }
        @AuraEnabled
        public Boolean canExpire { get; set; }
        @AuraEnabled
        public Boolean requiresProof { get; set; }
    }

    public class Qualification
    {
        @AuraEnabled
        public Id contactId { get; set;}
        @AuraEnabled
        public Id competencyId { get; set; }
        @AuraEnabled
        public Date validFrom { get; set; }
        @AuraEnabled
        public Date validTo { get; set;}
        @AuraEnabled
        public List<Id> attachmentIds { get; set;}
    }
}