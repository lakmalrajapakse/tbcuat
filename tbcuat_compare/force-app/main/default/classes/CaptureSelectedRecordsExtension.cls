public class CaptureSelectedRecordsExtension {
    public String selectedRecordIds { get; private set; }
 
    public CaptureSelectedRecordsExtension(ApexPages.StandardSetController controller) {
        List<SObject> selectedRecords = controller.getSelected();
        List<String> selectedIds = new List<String>();
 
        for (SObject selectedRecord : selectedRecords) {
            selectedIds.add(selectedRecord.get('Id').toString());
        }
 
        if (!selectedIds.isEmpty()) {
            selectedRecordIds = String.join(selectedIds, ',');
        }
    }
 }