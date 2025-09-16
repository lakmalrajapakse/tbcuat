public with sharing class ComplianceQualificationsController {
    @AuraEnabled
    public static List<ListQualification> getQualifications(Id contactId, List<String> categories) {
        List<sirenum__Ticket__c> qualifications = ComplianceService.getQualifications(contactId, categories);

        List<ListQualification> results = new List<ListQualification>();
        Map<Id, ListQualification> qualificationsById = new Map<Id, ListQualification>();

        for (sirenum__Ticket__c qual : qualifications) {
            ListQualification dto = new ListQualification();
            dto.id = qual.Id;
            dto.competencyName = qual.sirenum__TicketType__r.Name;
            dto.validFrom = qual.sirenum__Valid_from__c;
            dto.validTo = qual.sirenum__Valid_until__c;
            dto.valid = qual.sirenum__Valid__c;
            dto.attachments = new List<ListQualificationAttachment>();

            results.add(dto);
            qualificationsById.put(dto.id, dto);
        }

        if (qualifications.size() > 0) {
            List<ContentDocumentLink> qualificationAttachments = ComplianceService.getQualificationAttachments(
                new Map<Id, SObject>(qualifications).keySet()
            );

            for (ContentDocumentLink qualificationAttachment : qualificationAttachments) {
                ListQualification qual = qualificationsById.get(qualificationAttachment.LinkedEntityId);

                if (qual != null) {
                    ListQualificationAttachment attachment = new ListQualificationAttachment();
                    attachment.id = qualificationAttachment.id;
                    attachment.name = qualificationAttachment.ContentDocument.Title;
                    qual.attachments.add(attachment);
                }
            }
        }

        return results;
    }

    public class ListQualification {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String competencyName { get; set; }
        @AuraEnabled
        public Date validFrom { get; set; }
        @AuraEnabled
        public Date validTo { get; set; }
        @AuraEnabled
        public Boolean valid { get; set; }
        @AuraEnabled
        public List<ListQualificationAttachment> attachments { get; set; }
    }

    public class ListQualificationAttachment {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
    }
}