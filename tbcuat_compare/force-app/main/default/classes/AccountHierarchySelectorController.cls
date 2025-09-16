public with sharing class AccountHierarchySelectorController {
    @AuraEnabled(cacheable=true)
    public static String getAccountWithChildren(Id accountId) {
        try {
            List<Account> accounts = [
                SELECT
                    Id,
                    Name,
                    (
                        SELECT
                            Id,
                            Name,
                            (
                                SELECT
                                    Id,
                                    Name,
                                    (
                                        SELECT
                                            Id,
                                            Name,
                                            (
                                                SELECT Id, Name
                                                FROM ChildAccounts
                                                ORDER BY Name
                                            )
                                        FROM ChildAccounts
                                        ORDER BY Name
                                    )
                                FROM ChildAccounts
                                ORDER BY Name
                            )
                        FROM ChildAccounts
                        ORDER BY Name
                    )
                FROM Account
                WHERE Id = :accountId
                WITH USER_MODE
                ORDER BY Name
            ];

            return JSON.serialize(mapAccountsToDto(accounts));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<AccountDto> mapAccountsToDto(List<Account> accounts) {
        List<AccountDto> accountDtos = new List<AccountDto>();

        for (Account acc : accounts) {
            AccountDto dto = new AccountDto(acc.Id, acc.Name);

            if (!acc.ChildAccounts.isEmpty()) {
                dto.children = mapAccountsToDto(acc.ChildAccounts);
            }

            accountDtos.add(dto);
        }

        return accountDtos;
    }

    public class AccountDto {
        public Id recordId;
        public String name;
        public List<AccountDto> children;

        public AccountDto(Id recordId, String name) {
            this.recordId = recordId;
            this.name = name;
            this.children = new List<AccountDto>();
        }
    }
}