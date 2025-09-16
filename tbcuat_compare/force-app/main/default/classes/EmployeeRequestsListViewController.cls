public with sharing class EmployeeRequestsListViewController {
    @AuraEnabled
    public static List<EmployeeRequest> getEmployeeRequests(Id contactId) {
        List<EmployeeRequest> results = new List<EmployeeRequest>();

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT
                Id,
                Name,
                sirenum__Type__c,
                sirenum__Start_Time__c,
                sirenum__End_Time__c,
                sirenum__Approved__c,
                sirenum__Rejected__c
            FROM sirenum__Employee_Request__c
            WHERE sirenum__Contact__c = :contactId
            WITH USER_MODE
            ORDER BY sirenum__Approved__c, sirenum__Rejected__c, sirenum__Start_Time__c ASC
        ];

        for (sirenum__Employee_Request__c erRecord : employeeRequests) {
            EmployeeRequest er = new EmployeeRequest();
            er.id = erRecord.Id;
            er.name = erRecord.Name;
            er.type = erRecord.sirenum__Type__c;
            er.startDate = erRecord.sirenum__Start_Time__c;
            er.endDate = erRecord.sirenum__End_Time__c;
            er.approved = erRecord.sirenum__Approved__c;
            er.rejected = erRecord.sirenum__Rejected__c;
            results.add(er);
        }

        return results;
    }

    public class EmployeeRequest {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public DateTime startDate { get; set; }
        @AuraEnabled
        public DateTime endDate { get; set; }
        @AuraEnabled
        public Boolean approved { get; set; }
        @AuraEnabled
        public Boolean rejected { get; set; }
    }
}