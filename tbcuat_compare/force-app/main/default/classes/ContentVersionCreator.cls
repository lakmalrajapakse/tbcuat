/**
*  @description Apex class to create content version
**/
public with sharing class ContentVersionCreator {
    
    public String contentBody;
    public Id recordId;
    public String documentName;
    public String documentFormat;
    public ContentVersion contentVersion;
    public ContentDocumentLink contentDocumentLink;

    /**
    *  @description Constructor
    **/
    public ContentVersionCreator(String contentBody, Id recordId, String documentName, String documentFormat) {
        this.contentBody = contentBody;
        this.recordId = recordId;
        this.documentName = documentName;
        this.documentFormat = documentFormat;
    }

    /**
    * @description : Method to create content version
    **/
    public ContentVersion createContentVersion() {
        this.contentVersion = new ContentVersion(
            Title = this.documentName,
            VersionData = Blob.valueOf(this.contentBody),
            PathOnClient = this.documentName + '.' + this.documentFormat
        );
        return this.contentVersion;
    }

    /**
    * @description : Method to create content document link
    **/
    public ContentDocumentLink createContentDocumentLink(Id contentDocumentId) {
        this.contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = this.recordId,
            ContentDocumentId = contentDocumentId,
            shareType = 'I',
            Visibility = 'AllUsers'
        );
        return this.contentDocumentLink;
    }
}