@IsTest
private class NumberOfChildForAllAccounts_BatchTest {
    @TestSetup
    private static void makeData() {
        myTriggers.disable(TAG_AccountTypeHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(20);
        Account parentAccpunt1 = testAccounts[0];
        parentAccpunt1.CRM_AccountType__c = 'J';
        Account parentAccpunt2 = testAccounts[1];
        parentAccpunt2.CRM_AccountType__c = 'J';

        //child accounts
        for (Integer i = 2; i < 20; i++) {
            Account acc = testAccounts[i];
            if (i > 7) {
                acc.ParentId = parentAccpunt1.Id;
            } else {
                acc.ParentId = parentAccpunt2.Id;
            }
            acc.INT_ParentOrganizationNumber__c = '9000000000';
        }
        update testAccounts;
    }

    @IsTest
    private static void testBatchExecute() {
        Test.startTest();
        NumberOfChildForAllAccounts_Batch btch = new NumberOfChildForAllAccounts_Batch();
        Database.executeBatch(btch, 2000);
        Test.stopTest();
        List<Account> accounts = [
            SELECT TAG_NumberOfChildAccounts__c
            FROM Account
            WHERE TAG_NumberOfChildAccounts__c > 0
            ORDER BY TAG_NumberOfChildAccounts__c
        ];
        System.assertEquals(2, accounts.size(), 'Two parent accounts with child accounts');
        System.assertEquals(
            6,
            accounts[0].TAG_NumberOfChildAccounts__c,
            'First parent has 6 child'
        );
        System.assertEquals(
            12,
            accounts[1].TAG_NumberOfChildAccounts__c,
            'Second parent has 12 child'
        );
    }
}
