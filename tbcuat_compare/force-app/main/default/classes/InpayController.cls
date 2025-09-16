/**
*  @description Apex class to manage inpay webservices
**/
public with sharing class InpayController {
    
    /**
    *   @description : Method to fetch the holiday scheme for an employee from inpay
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getHolidayScheme(Id recordId) {
        Map<String, Object> objectsMap = new Map<String, Object>();
        String holidayScheme = '';
        
        if (recordId.getSobjectType().getDescribe().getName() == User.sObjectType.getDescribe().getName() || Test.isRunningTest()) {
            List<User> usersList = [SELECT Id, ContactId FROM User WHERE Id =: recordId LIMIT 1];
            recordId = !usersList.isEmpty() ? usersList[0].ContactId : (Test.isRunningTest() ? recordId : '');
        } else if (recordId.getSobjectType().getDescribe().getName() == sirenum__Employee_Request__c.sObjectType.getDescribe().getName()) {
            List<sirenum__Employee_Request__c> employeeRequests = [SELECT Id, sirenum__Contact__c FROM sirenum__Employee_Request__c WHERE Id =: recordId LIMIT 1];
            recordId = !employeeRequests.isEmpty() ? employeeRequests[0].sirenum__Contact__c : (Test.isRunningTest() ? recordId : '');
        }

        List<Contact> contactsList = [SELECT Id, InTimeExternalId__c, InPayReference__c FROM Contact WHERE Id =: recordId LIMIT 1];
        if (!contactsList.isEmpty() && !String.isBlank(contactsList[0].InPayReference__c)) {
            holidayScheme = InpaySyncHelper.getHolidayScheme(contactsList[0].InPayReference__c);
            // search holiday schemes in intime
            IntimeCalloutMock.systemName = 'Intime';
            Set<String> holidayClaimRefsList = IntimeSyncHelper.searchHolidayClaimsInIntime(contactsList[0].InPayReference__c);
            if (!holidayClaimRefsList.isEmpty()) {
                List<Object> holidayClaimRefsJsonList = IntimeSyncHelper.getHolidayClaimsFromIntime(holidayClaimRefsList);
                objectsMap.put('holidayAwaitingApproval',holidayClaimRefsJsonList);
            }
        }
        objectsMap.put('holidayScheme',holidayScheme);
        objectsMap.put('hasIntimeExternalId',!String.isBlank(contactsList[0].InPayReference__c));
        return objectsMap;
    }
}