public class ShiftPDFGenerator {
    public static void generateAndAttachPdfForTimesheet(Id timesheetId, List<sirenum__Shift__c> shifts) {
        // Create a PageReference for the Visualforce page
        PageReference pdfPage = Page.ShiftReportPDF; 
        
        // Pass the shifts to the Visualforce page using custom parameters
        pdfPage.getParameters().put('timesheetId', timesheetId);
        
        // Extract only the Shift IDs from the list of shifts
        List<String> shiftIds = new List<String>();
        for (sirenum__Shift__c shift : shifts) {
            shiftIds.add(shift.Id);
        }

        // Convert the List<Id> to a comma-separated String of IDs
        String shiftIdsString = String.join(shiftIds, ',');

        // Add the list of shift IDs to the page parameters
        pdfPage.getParameters().put('shiftIds', shiftIdsString);
        
        // Generate the PDF as a Blob
        Blob pdfBlob;
        if (!Test.isRunningTest()) {
            pdfBlob = pdfPage.getContent();
        }
        else {
            pdfBlob = Blob.valueOf('Test PDF Content');
        }

        sirenum__Timesheet__c timesheet =[select id,Name,sirenum__Worker__r.Name,InTimeId__c, ProofUploaded__c from sirenum__Timesheet__c where id =:timesheetId limit 1];

        // Create a ContentVersion record for the PDF
        //timesheet_<timesheetNumber>_<workers-inTimeExternalId>.pdf 
        ContentVersion contentVersion = new ContentVersion(
            Title = 'timesheet_' + timesheet.Name +'_'+timesheet.sirenum__Worker__r.Name+'-'+timesheet.InTimeId__c+'.pdf',
            PathOnClient = 'timesheet_' + timesheet.Name +'_'+timesheet.sirenum__Worker__r.Name+'-'+timesheet.InTimeId__c+'.pdf',
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert contentVersion;

        // Get the ContentDocumentId for linking the file
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;

        // Link the PDF to the Timesheet
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = timesheetId,
            ShareType = 'V' // 'V' for View access
        );
        insert contentLink;

        timesheet.ProofUploaded__c = true;
        update timesheet;
    }
}