public with sharing class ObjectSearchGridController {
    @AuraEnabled
    public static List<SObject> search(String searchTerm, String objectName, List<String> searchFields) {
        if (String.isBlank(searchTerm)) {
            return new List<SObject>();
        }

        String escapedSearchTerm = String.escapeSingleQuotes(searchTerm) + '*';
        String escapedObjectName = String.escapeSingleQuotes(objectName);
        String escapedFieldNames = String.escapeSingleQuotes(String.join(searchFields, ','));

        String searchquery =
            'FIND\'' +
            escapedSearchTerm +
            '*\'RETURNING ' +
            escapedObjectName +
            '(' +
            escapedFieldNames +
            ')';
        List<List<SObject>> searchResults = search.query(searchquery);

        return (List<SObject>) searchResults[0];
    }
}