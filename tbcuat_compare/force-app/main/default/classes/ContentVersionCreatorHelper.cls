/**
*  @description Helper class to create content version and content document link
**/
public with sharing class ContentVersionCreatorHelper {
    
    /**
    *  @description Method to create content version and content document link
    **/
    public static void createContentVersionsAndContentDocumentLinks(List<ContentVersionCreator> contentVersionCreatorList) {
        List<ContentVersion> contentVersionsToCreate = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinksToCreate = new  List<ContentDocumentLink>();

        // create content versions list
        for (ContentVersionCreator contentVersionCreator : contentVersionCreatorList) {
            contentVersionsToCreate.add(contentVersionCreator.createContentVersion());
        }
        if (!contentVersionsToCreate.isEmpty()) insert contentVersionsToCreate;

        Map<Id, ContentVersion> contentVersionsMap = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionsToCreate]);

        // create content document links
        for (ContentVersionCreator contentVersionCreator : contentVersionCreatorList) {
            if (contentVersionsMap.containsKey(contentVersionCreator.contentVersion.Id)) {
                contentDocumentLinksToCreate.add(contentVersionCreator.createContentDocumentLink(contentVersionsMap.get(contentVersionCreator.contentVersion.Id).ContentDocumentId));
            }
        }
        if (!contentDocumentLinksToCreate.isEmpty()) insert contentDocumentLinksToCreate;
    }

    /**
    *  @description Method to create an instance of content creator
    **/
    public static ContentVersionCreator createContentVersionCreator(String contentBody, Id recordId, String documentName, String documentFormat) {
        return new ContentVersionCreator(contentBody, recordId, documentName, documentFormat);
    }
}