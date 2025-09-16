/**
* @description Apex class used to manage user profile picture
**/
public without sharing class UserProfilePictureController {

    /**
    * @description Method to get set photo
    **/
    @AuraEnabled
    public static String getPhotoUrl(Id recordId) {
        String photoUrl = '';
        List<Contact> contactsList = [SELECT Id, sirenum__Photo_ID__c FROM Contact WHERE Id =: recordId];
        if (!contactsList.isEmpty()) {
            List<ContentVersion> contentVersionsList = [SELECT Id, b3d__Identifier__c, VersionDataUrl FROM ContentVersion WHERE b3d__Identifier__c =: contactsList[0].sirenum__Photo_ID__c LIMIT 1];
            if (!contentVersionsList.isEmpty()) photoUrl = contentVersionsList[0].VersionDataUrl;
        }
        return photoUrl;
    }

    /**
    * @description Method to get set photo
    **/
    @AuraEnabled
    public static String manageAttachment(String fileName, Id recordId, String base64Data) {
        Attachment attachment = new Attachment(
            Name = fileName,
            Body = EncodingUtil.base64Decode(base64Data),
            ParentId = recordId
        );
        insert attachment;
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = EncodingUtil.base64Decode(base64Data),
            b3d__Identifier__c = attachment.Id
        );
        insert contentVersion;
        List<Contact> contactsList = [SELECT Id, sirenum__Photo_ID__c, PhotoUrl FROM Contact WHERE Id =: recordId];
        if (!contactsList.isEmpty() && !String.isBlank(contactsList[0].sirenum__Photo_ID__c)) {
            List<ContentDocument> contentDocumentsList = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersion.b3d__Identifier__c =: contactsList[0].sirenum__Photo_ID__c LIMIT 1];
            if (!contentDocumentsList.isEmpty()) delete contentDocumentsList;
            List<Attachment> attachmentsList = [SELECT Id FROM Attachment WHERE Id =: contactsList[0].sirenum__Photo_ID__c LIMIT 1];
            if (!attachmentsList.isEmpty()) delete attachmentsList;
        }
        if(!contactsList.isEmpty()){
            contactsList[0].sirenum__Photo_ID__c = attachment.Id;
            update contactsList;
        }
        return getPhotoUrl(recordId);
    }
}