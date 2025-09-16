@isTest
private class AccountHierarchySelectorControllerTest {
    @isTest
    static void getAccountWithChildren_givenAccountWithChildren_returnsHierarchicalDtosMappedCorrectly() {
        // GIVEN
        Account acc = new Account(Name = 'Root');
        insert acc;

        Account childAcc = new Account(Name = 'Child', parentId = acc.Id);
        insert childAcc;

        Account grandChildAcc = new Account(Name = 'Grandchild', parentId = childAcc.Id);
        insert grandChildAcc;

        Account childAcc2 = new Account(Name = 'Child 2', parentId = acc.Id);
        insert childAcc2;

        // WHEN
        String accountDtosJson = AccountHierarchySelectorController.getAccountWithChildren(acc.Id);

        // THEN
        List<AccountHierarchySelectorController.AccountDto> accountDtos = (List<AccountHierarchySelectorController.AccountDto>) JSON.deserialize(
            accountDtosJson,
            List<AccountHierarchySelectorController.AccountDto>.class
        );
        Assert.areEqual(1, accountDtos.size(), 'Should be a single root node');
        Assert.areEqual(acc.Name, accountDtos.get(0).name, 'Root should have correct name');
        Assert.areEqual(acc.Id, accountDtos.get(0).recordId, 'Root should have correct Id');

        List<AccountHierarchySelectorController.AccountDto> childAccountDtos = accountDtos.get(0).children;
        Assert.areEqual(2, childAccountDtos.size(), 'Should be two child nodes');
        Assert.areEqual(childAcc.Name, childAccountDtos.get(0).name, 'Child node should have correct name');
        Assert.areEqual(childAcc.Id, childAccountDtos.get(0).recordId, 'Child node should have correct Id');
        Assert.areEqual(childAcc2.Name, childAccountDtos.get(1).name, 'Child node should have correct name');
        Assert.areEqual(childAcc2.Id, childAccountDtos.get(1).recordId, 'Child node should have correct Id');

        List<AccountHierarchySelectorController.AccountDto> grandChildAccountDtos = childAccountDtos.get(0).children;
        Assert.areEqual(1, grandChildAccountDtos.size(), 'Should be two grandchild nodes');
        Assert.areEqual(
            grandChildAcc.Name,
            grandChildAccountDtos.get(0).name,
            'Grandchild node should have correct name'
        );
        Assert.areEqual(
            grandChildAcc.Id,
            grandChildAccountDtos.get(0).recordId,
            'Grandchild node should have correct Id'
        );

        List<AccountHierarchySelectorController.AccountDto> grandChildAccountDtos2 = childAccountDtos.get(1).children;
        Assert.areEqual(
            0,
            grandChildAccountDtos2.size(),
            'Should not be any grandchild nodes under the second child account'
        );
    }

    @isTest
    static void getAccountWithChildren_givenAccountWithNoChildren_returnsHierarchicalDtosMappedCorrectly() {
        // GIVEN
        Account acc = new Account(Name = 'Root');
        insert acc;

        // WHEN
        String accountDtosJson = AccountHierarchySelectorController.getAccountWithChildren(acc.Id);

        // THEN
        List<AccountHierarchySelectorController.AccountDto> accountDtos = (List<AccountHierarchySelectorController.AccountDto>) JSON.deserialize(
            accountDtosJson,
            List<AccountHierarchySelectorController.AccountDto>.class
        );
        Assert.areEqual(1, accountDtos.size(), 'Should be a single root node');
        Assert.areEqual(acc.Name, accountDtos.get(0).name, 'Root should have correct name');
        Assert.areEqual(acc.Id, accountDtos.get(0).recordId, 'Root should have correct Id');

        List<AccountHierarchySelectorController.AccountDto> childAccountDtos = accountDtos.get(0).children;
        Assert.areEqual(0, childAccountDtos.size(), 'Root should have no children');
    }

    @isTest
    static void getAccountWithChildren_givenAccountWithMoreThanMaxDepthChildren_returnsHierarchyLimitedTo5Deep() {
        // GIVEN
        Account acc = new Account(Name = 'Root');
        insert acc;

        Account childAcc = new Account(Name = 'Child', parentId = acc.Id);
        insert childAcc;

        Account grandChildAcc = new Account(Name = 'Grandchild', parentId = childAcc.Id);
        insert grandChildAcc;

        Account greatGrandChildAcc = new Account(Name = 'Great Grandchild', parentId = grandChildAcc.Id);
        insert greatGrandChildAcc;

        Account greatGreatGrandChildAcc = new Account(
            Name = 'Great Great Grandchild',
            parentId = greatGrandChildAcc.Id
        );
        insert greatGreatGrandChildAcc;

        Account greatGreatGreatGrandChildAcc = new Account(
            Name = 'Great Great Great Grandchild',
            parentId = greatGreatGrandChildAcc.Id
        );
        insert greatGreatGreatGrandChildAcc;

        // WHEN
        String accountDtosJson = AccountHierarchySelectorController.getAccountWithChildren(acc.Id);

        // THEN
        List<AccountHierarchySelectorController.AccountDto> accountDtos = (List<AccountHierarchySelectorController.AccountDto>) JSON.deserialize(
            accountDtosJson,
            List<AccountHierarchySelectorController.AccountDto>.class
        );
        Assert.areEqual(1, accountDtos.size(), 'Should be a single root node');
        Assert.areEqual(acc.Name, accountDtos.get(0).name, 'Root should have correct name');
        Assert.areEqual(acc.Id, accountDtos.get(0).recordId, 'Root should have correct Id');

        List<AccountHierarchySelectorController.AccountDto> childAccountDtos = accountDtos.get(0).children;
        Assert.areEqual(1, childAccountDtos.size(), 'Should be two child nodes');
        Assert.areEqual(childAcc.Name, childAccountDtos.get(0).name, 'Child node should have correct name');
        Assert.areEqual(childAcc.Id, childAccountDtos.get(0).recordId, 'Child node should have correct Id');

        List<AccountHierarchySelectorController.AccountDto> grandChildAccountDtos = childAccountDtos.get(0).children;
        Assert.areEqual(1, grandChildAccountDtos.size(), 'Should be two grandchild nodes');
        Assert.areEqual(
            grandChildAcc.Name,
            grandChildAccountDtos.get(0).name,
            'Grandchild node should have correct name'
        );
        Assert.areEqual(
            grandChildAcc.Id,
            grandChildAccountDtos.get(0).recordId,
            'Grandchild node should have correct Id'
        );

        List<AccountHierarchySelectorController.AccountDto> greatGrandChildAccountDtos = grandChildAccountDtos.get(0)
            .children;
        Assert.areEqual(1, greatGrandChildAccountDtos.size(), 'Should be one grandchild node');
        Assert.areEqual(
            greatGrandChildAcc.Name,
            greatGrandChildAccountDtos.get(0).name,
            'Grandchild node should have correct name'
        );
        Assert.areEqual(
            greatGrandChildAcc.Id,
            greatGrandChildAccountDtos.get(0).recordId,
            'Grandchild node should have correct Id'
        );

        List<AccountHierarchySelectorController.AccountDto> greatGreatGrandChildAccountDtos = greatGrandChildAccountDtos.get(
                0
            )
            .children;
        Assert.areEqual(1, greatGreatGrandChildAccountDtos.size(), 'Should be one great grandchild node');
        Assert.areEqual(
            greatGreatGrandChildAcc.Name,
            greatGreatGrandChildAccountDtos.get(0).name,
            'Grandchild node should have correct name'
        );
        Assert.areEqual(
            greatGreatGrandChildAcc.Id,
            greatGreatGrandChildAccountDtos.get(0).recordId,
            'Grandchild node should have correct Id'
        );

        List<AccountHierarchySelectorController.AccountDto> greatGreatGreatGrandChildAccountDtos = greatGreatGrandChildAccountDtos.get(
                0
            )
            .children;
        Assert.areEqual(0, greatGreatGreatGrandChildAccountDtos.size(), 'Should be one great grandchild node');
    }

    @isTest
    static void getAccountWithChildren_givenInsufficientAccess_throwsAuraHandledException() {
        // GIVEN
        Profile userProfile = [SELECT id FROM profile WHERE name = 'Minimum Access - API Only Integrations'];

        User standardUser = new User(
            Alias = 'stuse123',
            Email = 'standarduser123@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser123@example.com.tbc'
        );
        insert standardUser;

        // WHEN
        String exType = '';

        String accountDtosJson;

        System.runAs(standardUser) {
            try {
                accountDtosJson = AccountHierarchySelectorController.getAccountWithChildren(null);
                Assert.fail('Shouldve thrown an AuraHandledException');
            } catch (Exception ex) {
                exType = ex.getTypeName();
            }
        }

        // THEN
        Assert.areEqual('System.AuraHandledException', exType, 'Method shouldve thrown an AuraHandledException');
    }
}