@IsTest
private class NavUnitAccountRoutingServiceTest {
    @TestSetup
    private static void makeData() {
        TestDataFactory.getQueue('NAV Drammen', 'queue_602', 'TemporaryLayoff__c');
        TestDataFactory.getQueue('NAV Asker', 'queue_220', 'TemporaryLayoff__c');
    }

    @IsTest
    private static void testGetNavUnits() {
        myTriggers.disable(TAG_AccountTypeHandler.class);
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        List<Account> testAccounts = TAG_TestDataFactory.createAccounts(20);
        for (Integer i = 0; i < 20; i++) {
            Account acc = testAccounts[i];
            if (i > 7) {
                acc.INT_MunicipalityNumber__c = '3301';
            } else {
                acc.INT_MunicipalityNumber__c = '3203';
            }
        }
        update testAccounts;

        List<NavUnit__c> units = new List<NavUnit__c>();
        units.add(new NavUnit__c(Name = 'NAV Drammen', INT_UnitNumber__c = '0602'));
        units.add(new NavUnit__c(Name = 'NAV Asker', INT_UnitNumber__c = '0220'));
        insert units;

        List<Account> accounts = [
            SELECT INT_MunicipalityNumber__c, ShippingPostalCode, TAG_NavUnit__c, TAG_NavUnit__r.Name
            FROM Account
            ORDER BY INT_MunicipalityNumber__c DESC
        ];

        Test.startTest();
        List<Account> accountsWithUnits = NavUnitAccountRoutingService.getNavUnits(accounts);
        Test.stopTest();

        System.assertEquals(units[0].Id, accountsWithUnits[0].TAG_NavUnit__c, 'First account belongs to Asker');
        System.assertEquals(units[1].Id, accountsWithUnits[19].TAG_NavUnit__c, 'Last account belongs to Drammen');
    }
}
