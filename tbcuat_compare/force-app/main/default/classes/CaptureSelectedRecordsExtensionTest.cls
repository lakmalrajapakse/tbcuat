@isTest
private class CaptureSelectedRecordsExtensionTest {
    @isTest
    static void testSelectedRecordIds() {
        // Insert test records
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'TestContact1'),
            new Contact(LastName = 'TestContact2')
        };
        insert contacts;

        // Create a new StandardSetController with the test records
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);

        // Select the records using the StandardSetController
        ssc.setSelected(contacts);

        // Instantiate the CaptureSelectedRecordsExtension with the StandardSetController
        CaptureSelectedRecordsExtension extension = new CaptureSelectedRecordsExtension(ssc);

        // Retrieve the selectedRecordIds from the extension
        String selectedRecordIds = extension.selectedRecordIds;

        // Assert that the selectedRecordIds string contains the IDs of the inserted contacts
        for (Contact c : contacts) {
            System.assert(selectedRecordIds.contains(c.Id), 'The selectedRecordIds should contain the contact ID.');
        }
    }
}