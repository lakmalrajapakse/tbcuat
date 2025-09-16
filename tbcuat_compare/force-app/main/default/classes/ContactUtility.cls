public class ContactUtility {
    /**
     * Generates a list of Contact records with randomized values for testing.
     * 
     * @param numberOfContactsToCreate The number of Contact records to create.
     * @return List of Contact records.
     */
    public static List<Contact> generateRandomContacts(Integer numberOfContactsToCreate) {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < numberOfContactsToCreate; i++) {
            Contact contact = new Contact(
                FirstName = 'FirstName' + i,
                LastName = 'LastName' + i,
                Email = 'email' + i + '@example.com',
                MobilePhone = '(123) 456-789' + i
            );

            contacts.add(contact);
        }

        return contacts;
    }
}