public with sharing class PayQueriesListViewController {
    @AuraEnabled
    public static List<PayQuery> getPayQueries(Id contactId) {
        List<PayQuery> results = new List<PayQuery>();

        List<Pay_Query__c> payQueries = [
            SELECT Id, Name, Type__c, Description_of_your_Query__c, Status__c, Escalate_to_Payroll__c, Payslip_Date__c,TBC_Comments__c
            FROM Pay_Query__c
            WHERE Person__c = :contactId
            WITH USER_MODE
            ORDER BY Name ASC
        ];

        for (Pay_Query__c payQueryRecord : payQueries) {
            PayQuery payQuery = new PayQuery();
            payQuery.id = payQueryRecord.Id;
            payQuery.name = payQueryRecord.Name;
            payQuery.type = payQueryRecord.Type__c;
            payQuery.status = payQueryRecord.Status__c;
            payQuery.description = payQueryRecord.Description_of_your_Query__c;
            payQuery.paySlipDate = payQueryRecord.Payslip_Date__c;
            payQuery.escalateToPayroll = payQueryRecord.Escalate_to_Payroll__c;
            payQuery.comments = payQueryRecord.TBC_Comments__c;
            results.add(payQuery);
        }

        return results;
    }

    public class PayQuery {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public Date paySlipDate { get; set; }
        @AuraEnabled
        public Boolean escalateToPayroll { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String comments { get; set; }
    }
}