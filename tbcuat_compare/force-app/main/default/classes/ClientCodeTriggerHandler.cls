public without sharing class ClientCodeTriggerHandler extends TriggerHandler{
    private static final String CODE_FILLER = 'Z';
    private static final Integer START_NUMBER = 4000;

    /**
     * @description Method to set Client Code for Accounts
     * @param accs List of Account records
     */
    public static void setClientCode(Account [] accs) {
        Map <String, List<Account>> accountsMap = new Map <String, List<Account>>();

        for (Account acc : accs) {
            // Get 4 char prefix
            String clientPrefix = acc.Name.replaceAll('[^a-zA-Z0-9]','').toUpperCase().left(4);
            Integer length = clientPrefix.length();
                // System.debug('length: ' + length);
            if (length<4){
                Integer count = 4 - length;
                for (Integer i = 0; i < count; i++){
                    clientPrefix += CODE_FILLER;
                }
            }

            if (accountsMap.containsKey(clientPrefix)) {
                accountsMap.get(clientPrefix).add(acc);
            } else {
                accountsMap.put(clientPrefix, new List<Account>{acc});
            }        
        }

        List<Client_Code_Prefix__c> clientCodePrefixes = 
            [SELECT Id, Client_Code_Prefix__c,Client_Code_Number__c 
             FROM Client_Code_Prefix__c 
             WHERE Client_Code_Prefix__c = :accountsMap.keySet()];

        Map<String, Client_Code_Prefix__c> clientCodePrefixMap = new Map<String, Client_Code_Prefix__c>();
        for (Client_Code_Prefix__c clientCodePrefix : clientCodePrefixes) {
            clientCodePrefixMap.put(clientCodePrefix.Client_Code_Prefix__c, clientCodePrefix);
        }
        
        List<Client_Code_Prefix__c> clientCodePrefixesToInsert = new List<Client_Code_Prefix__c>();
        for (String clientPrefix : accountsMap.keySet()) {
            Client_Code_Prefix__c existingPrefix = clientCodePrefixMap.get(clientPrefix);
            if (existingPrefix == null) {
                existingPrefix = new Client_Code_Prefix__c(
                    Client_Code_Prefix__c = clientPrefix,
                    Client_Code_Number__c = START_NUMBER -1
                );

                clientCodePrefixesToInsert.add(existingPrefix);                
            } 

            for (Account acc : accountsMap.get(clientPrefix)) { 
                existingPrefix.Client_Code_Number__c = existingPrefix.Client_Code_Number__c + 1;            
                acc.Client_Code__c = existingPrefix.Client_Code_Prefix__c + String.valueOf(existingPrefix.Client_Code_Number__c.intValue());
            }
        }

        if (!clientCodePrefixesToInsert.isEmpty()) {
            insert clientCodePrefixesToInsert;            
        }

        if (!clientCodePrefixMap.isEmpty()) {
            update clientCodePrefixMap.values();            
        }
    }
}