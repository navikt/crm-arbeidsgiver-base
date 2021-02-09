@IsTest
private class PopulateNavUnitForAllAccounts_BatchTest {
    @TestSetup
    private static void makeData() {
        TestDataFactory.getQueue(
            'NAV Drammen',
            'queue_602',
            'TemporaryLayoff__c'
        );
    }

    @IsTest
    private static void testExecute() {
        List<NavUnit__c> units = new List<NavUnit__c>();
        units.add(
            new NavUnit__c(Name = 'NAV Drammen', INT_UnitNumber__c = '0602')
        );
        insert units;

        myTriggers.disable(TAG_AccountTypeHandler.class);
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(50);

        Test.startTest();
        PopulateNavUnitForAllAccounts_Batch btch = new PopulateNavUnitForAllAccounts_Batch();
        Database.executeBatch(btch, 2000);
        Test.stopTest();
        System.assertEquals(
            50,
            [SELECT COUNT() FROM Account WHERE TAG_NAvUnit__c = :units[0].Id],
            'All accounts belongs to Drammen'
        );
    }
}
