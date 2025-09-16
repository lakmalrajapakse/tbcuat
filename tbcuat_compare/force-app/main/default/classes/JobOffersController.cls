public with sharing class JobOffersController {
    @AuraEnabled
    public static List<JobOffer> getJobOffers(Id contactId) {
        try {
            List<JobOffer> results = new List<JobOffer>();

            List<sirenum__Shift_Invitation__c> shiftInvitations = [
                SELECT Id, Shift_Site_Name__c, Shift_Start_Time__c, Shift_End_Time__c, Shift_Forecast_Pay__c
                FROM sirenum__Shift_Invitation__c
                WHERE
                    sirenum__Contact__c = :contactId
                    AND sirenum__Is_Shift_Invitation__c = TRUE
                    AND sirenum__Status__c = 'Broadcasting'
                WITH USER_MODE
            ];

            for (sirenum__Shift_Invitation__c shiftInvitation : shiftInvitations) {
                JobOffer jobOffer = new JobOffer();
                jobOffer.Id = shiftInvitation.Id;
                jobOffer.name = shiftInvitation.Shift_Site_Name__c;
                jobOffer.startTime = DateTime.valueOf(shiftInvitation.Shift_Start_Time__c);
                jobOffer.endTime = DateTime.valueOf(shiftInvitation.Shift_End_Time__c);
                jobOffer.forecastPay = shiftInvitation.Shift_Forecast_Pay__c;
                results.add(jobOffer);
            }

            return results;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void decline(Id offerId) {
        try {
            List<sirenum__Shift_Invitation__c> shiftInvitations = [
                SELECT Id, sirenum__Status__c
                FROM sirenum__Shift_Invitation__c
                WHERE Id = :offerId
                WITH USER_MODE
            ];

            if (shiftInvitations.size() < 1) {
                throw new ControllerException('Unable to find offer with id: ' + offerId);
            }

            shiftInvitations.get(0).sirenum__Status__c = 'Declined';

            Database.update(shiftInvitations.get(0), AccessLevel.USER_MODE);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void accept(Id offerId) {
        try {
            List<sirenum__Shift_Invitation__c> shiftInvitations = [
                SELECT Id, sirenum__Status__c
                FROM sirenum__Shift_Invitation__c
                WHERE Id = :offerId
                WITH USER_MODE
            ];

            if (shiftInvitations.size() < 1) {
                throw new ControllerException('Unable to find offer with id: ' + offerId);
            }

            shiftInvitations.get(0).sirenum__Status__c = 'Accepted';

            Database.update(shiftInvitations.get(0), AccessLevel.USER_MODE);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class ControllerException extends Exception {
    }

    public class JobOffer {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Datetime startTime { get; set; }
        @AuraEnabled
        public Datetime endTime { get; set; }
        @AuraEnabled
        public Decimal forecastPay { get; set; }
    }
}