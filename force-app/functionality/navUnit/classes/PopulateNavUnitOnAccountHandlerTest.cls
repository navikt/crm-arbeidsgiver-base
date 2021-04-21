@IsTest
private class PopulateNavUnitOnAccountHandlerTest {
    @TestSetup
    private static void makeData() {
        TestDataFactory.getQueue('NAV Drammen', 'queue_602', 'TemporaryLayoff__c');
        TestDataFactory.getQueue('NAV Asker', 'queue_220', 'TemporaryLayoff__c');
    }

    @IsTest
    private static void testOnBeforeInsert() {
        List<NavUnit__c> units = new List<NavUnit__c>();
        units.add(new NavUnit__c(Name = 'NAV Drammen', INT_UnitNumber__c = '0602'));
        insert units;

        myTriggers.disable(TAG_AccountTypeHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(50);

        System.assertEquals(
            50,
            [SELECT COUNT() FROM Account WHERE TAG_NAvUnit__c = :units[0].Id],
            'All accounts belongs to Drammen'
        );
    }

    @IsTest
    private static void testOnBeforeUpdate() {
        List<NavUnit__c> units = new List<NavUnit__c>();
        units.add(new NavUnit__c(Name = 'NAV Drammen', INT_UnitNumber__c = '0602'));
        units.add(new NavUnit__c(Name = 'NAV Asker', INT_UnitNumber__c = '0220'));
        insert units;

        myTriggers.disable(TAG_AccountTypeHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(50);

        Test.startTest();
        testAccounts[0].INT_MunicipalityNumber__c = '3025';
        testAccounts[1].INT_MunicipalityNumber__c = '3025';
        update testAccounts;
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM Account WHERE TAG_NAvUnit__c = :units[1].Id],
            'Two accounts is moved to Asker'
        );
        System.assertEquals(
            48,
            [SELECT COUNT() FROM Account WHERE TAG_NAvUnit__c = :units[0].Id],
            '48 accounts still in Drammen'
        );
    }
}