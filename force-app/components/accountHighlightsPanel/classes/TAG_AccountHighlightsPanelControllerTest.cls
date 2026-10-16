@IsTest
private class TAG_AccountHighlightsPanelControllerTest {
    private static final Integer CHILD_COUNT = 12;

    @TestSetup
    private static void makeData() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(CHILD_COUNT + 2);
        Account jAccount = accounts[0];
        jAccount.Name = 'J enhet';
        Account unrelatedAccount = accounts[1];
        unrelatedAccount.Name = 'Annen enhet';
        for (Integer i = 2; i < accounts.size(); i++) {
            accounts[i].Name = 'B enhet ' + String.valueOf(100 - i);
            accounts[i].ParentId = jAccount.Id;
            accounts[i].ShippingCity = 'Oslo';
        }
        update accounts;
    }

    private static Account getJAccount() {
        return [SELECT Id FROM Account WHERE Name = 'J enhet' LIMIT 1];
    }

    @IsTest
    private static void returnsFirstTenChildrenSortedByNameWithTotalCount() {
        Id jAccountId = getJAccount().Id;

        Test.startTest();
        TAG_AccountHighlightsPanelController.RelatedAccounts result = TAG_AccountHighlightsPanelController.getRelatedAccounts(
            jAccountId
        );
        Test.stopTest();

        Assert.areEqual(CHILD_COUNT, result.totalCount, 'Total count should include all children');
        Assert.areEqual(10, result.accounts.size(), 'Only the first ten children should be returned');
        for (Integer i = 1; i < result.accounts.size(); i++) {
            Assert.isTrue(result.accounts[i - 1].Name <= result.accounts[i].Name, 'Children should be sorted by name');
        }
        for (Account child : result.accounts) {
            Assert.areNotEqual(jAccountId, child.Id, 'The J account itself should be excluded');
            Assert.areEqual('Oslo', child.ShippingCity, 'Shipping city should be returned');
        }
    }

    @IsTest
    private static void returnsEmptyResultForAccountWithoutChildren() {
        Account unrelatedAccount = [SELECT Id FROM Account WHERE Name = 'Annen enhet' LIMIT 1];

        TAG_AccountHighlightsPanelController.RelatedAccounts result = TAG_AccountHighlightsPanelController.getRelatedAccounts(
            unrelatedAccount.Id
        );

        Assert.areEqual(0, result.totalCount, 'No children expected');
        Assert.isTrue(result.accounts.isEmpty(), 'No children expected');
    }

    @IsTest
    private static void returnsEmptyResultForNullId() {
        TAG_AccountHighlightsPanelController.RelatedAccounts result = TAG_AccountHighlightsPanelController.getRelatedAccounts(
            null
        );

        Assert.areEqual(0, result.totalCount, 'Null id should not match accounts without ultimate parent');
        Assert.isTrue(result.accounts.isEmpty(), 'Null id should return no accounts');
    }

    @IsTest
    private static void getEmployeesReturnsGroupedValue() {
        Account jAccount = getJAccount();
        jAccount.INT_HasEmployees__c = true;
        jAccount.NumberOfEmployees = 3;
        update jAccount;

        Assert.areEqual(
            '1-4',
            TAG_AccountHighlightsPanelController.getEmployees(jAccount.Id),
            'Small employers are grouped'
        );
    }
}
