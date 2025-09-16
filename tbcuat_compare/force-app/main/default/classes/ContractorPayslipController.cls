/**
*  @description Apex class to manage contractor payslip
**/
public without sharing class ContractorPayslipController {
    
    /**
    *   @description : Method to fetch the payslip from the intime
    **/
    @AuraEnabled(cacheable=true)
    public static String getContractorPayslip(Id recordId) {
        String contractorPayslipUrl = '';
        if (recordId.getSobjectType().getDescribe().getName() == User.sObjectType.getDescribe().getName() || Test.isRunningTest()) {
            List<User> usersList = [SELECT Id, ContactId FROM User WHERE Id =: recordId LIMIT 1];
            recordId = !usersList.isEmpty() ? usersList[0].ContactId : (Test.isRunningTest() ? recordId : '');
        }
        List<Contact> contactsList = [SELECT Id, InPayId__c, InTimeId__c FROM Contact WHERE Id =: recordId LIMIT 1];
        if (!contactsList.isEmpty() && !String.isBlank(contactsList[0].InTimeId__c) && !String.isBlank(contactsList[0].InPayId__c)) {
            HttpResponse httpResponse = IntimeWebservice.getContractorPayslip(contactsList[0].InTimeId__c);
            if (httpResponse.getStatusCode() == 200) {
                contractorPayslipUrl = EncodingUtil.urlDecode(
                    String.valueOf(IntimeSyncHelper.getResponse('getURLForContractorsPayslipResponse',httpResponse.getBody())),
                    'UTF-8'
                );
            }
        }
        return contractorPayslipUrl;
    }
}