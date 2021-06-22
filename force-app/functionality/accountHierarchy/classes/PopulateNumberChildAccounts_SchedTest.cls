@IsTest
private class PopulateNumberChildAccounts_SchedTest {
    @TestSetup
    private static void makeData() {
        myTriggers.disable(TAG_AccountTypeHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(20);
        Account parentAccpunt1 = testAccounts[0];
        Account parentAccpunt2 = testAccounts[1];

        List<AccountHistory> accountHistoryList = new List<AccountHistory>();
        //child accounts
        for (Integer i = 2; i < 20; i++) {
            Account acc = testAccounts[i];
            if (i > 8) {
                acc.ParentId = parentAccpunt1.Id;
            } else {
                acc.ParentId = parentAccpunt2.Id;
            }
            acc.INT_ParentOrganizationNumber__c = '9000000000';

            AccountHistory history = new AccountHistory();
            history.AccountId = acc.Id;
            history.Field = 'INT_ParentOrganizationNumber__c';
            accountHistoryList.add(history);
        }
        update testAccounts;
        insert accountHistoryList;
    }

    @IsTest
    private static void testQuery() {
        PopulateNumberChildAccounts_Schedule schedClass = new PopulateNumberChildAccounts_Schedule();
        String query = schedClass.ACCOUNT_HISTORY_QUERY;
        test.startTest();
        List<AccountHistory> history = Database.query(query);
        test.stopTest();
        System.assertEquals(18, history.size(), '18 changed child accounts in test data setup');
    }

    @IsTest
    private static void testBatchExecute() {
        Test.startTest();
        PopulateNumberChildAccounts_Schedule btch = new PopulateNumberChildAccounts_Schedule();
        Database.executeBatch(btch, 2000);
        Test.stopTest();
        List<Account> accounts = [
            SELECT TAG_NumberOfChildAccounts__c
            FROM Account
            WHERE TAG_NumberOfChildAccounts__c > 0
            ORDER BY TAG_NumberOfChildAccounts__c
        ];
        System.assertEquals(2, accounts.size(), 'Two parent accounts with child accounts');
        System.assertEquals(7, accounts[0].TAG_NumberOfChildAccounts__c, 'First parent has 7 child');
        System.assertEquals(11, accounts[1].TAG_NumberOfChildAccounts__c, 'Second parent has 11 child');
    }

    @IsTest
    private static void testScheduleExecute() {
        Test.startTest();
        PopulateNumberChildAccounts_Schedule scheduleClass = new PopulateNumberChildAccounts_Schedule();
        String chron = '0 0 23 * * ?';
        System.schedule('Populate child accounts', chron, scheduleClass);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'Populate child accounts'], 'A job should be scheduled');
    }
}
