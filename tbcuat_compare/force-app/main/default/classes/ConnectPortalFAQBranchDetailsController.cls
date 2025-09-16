/**
* @File Name : ConnectPortalFAQBranchDetailsController.cls
* @Description : picks up the contacts branch details from the plan and the record owner for display purposes in a LWC to be shown in the customer community.
* @Author : 1218Global
* @Last Modified By :
* @Last Modified On : May 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 28, 2025 |   | Initial Version
**/

public without sharing class ConnectPortalFAQBranchDetailsController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getBranchDetails() {
        //We need to get the contact details for the currently running user.
        User userRecord = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];

        if(userRecord != null && userRecord.ContactId != null){
        
            Contact contactRecord = [
                SELECT 
                    Plan_Code__r.Branch__r.Name,
                    Owner.Name,
                    Owner.Email,
                    Owner.Phone
                FROM Contact
                WHERE Id = :userRecord.ContactId
                LIMIT 1
            ];
            
            Map<String, String> result = new Map<String, String>();
            result.put('branchName', contactRecord.Plan_Code__r != null && contactRecord.Plan_Code__r.Branch__r != null ? contactRecord.Plan_Code__r.Branch__r.Name : '');
            result.put('contactName', contactRecord.Owner != null ? contactRecord.Owner.Name : '');
            result.put('contactEmail', contactRecord.Owner != null ? contactRecord.Owner.Email : '');
            result.put('contactPhone', contactRecord.Owner != null ? contactRecord.Owner.Phone : '');
            
            return result;

        } else {
            return null;
        }
    }
}