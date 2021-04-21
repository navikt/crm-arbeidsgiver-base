@IsTest
public class TAG_TemporaryLayoffRoutingHandlerTest {
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('NAV Lister', 'queue_1037', 'TemporaryLayoff__c');
        TestDataFactory.getQueue('NAV Eidsvoll', 'queue_237', 'TemporaryLayoff__c');
        TestDataFactory.getQueue('NAV Lerkendal', 'queue_5702', 'TemporaryLayoff__c');
    }

    @IsTest
    private static void insertTemporaryLayoff() {
        NavUnit__c navUnit = TestDataFactory.getNavUnits(1, false)[0];
        navUnit.INT_UnitNumber__c = '1037';
        insert navUnit;

        Account account = TAG_TestDataFactory.createAccounts(1)[0];
        account.INT_MunicipalityNumber__c = '4206';
        update account;

        Test.startTest();
        TemporaryLayoff__c temporaryLayoff = TAG_TestDataFactory.getTemporaryLayoffs(1, account, true)[0];
        Test.stopTest();

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_1037'];
        TemporaryLayoff__c insertedTemporaryLayoff = [SELECT OwnerId, NAV_Unit__c FROM TemporaryLayoff__c LIMIT 1];
        System.assertEquals(queue.Id, insertedTemporaryLayoff.OwnerId);
        System.assertEquals(navUnit.Id, insertedTemporaryLayoff.NAV_Unit__c);
    }

    @IsTest
    private static void inserWhenMatchingQueueButNoMatchingNavUnit() {
        Account account = TAG_TestDataFactory.createAccounts(1)[0];
        account.INT_MunicipalityNumber__c = '3035';
        update account;

        Test.startTest();
        TemporaryLayoff__c temporaryLayoff = TAG_TestDataFactory.getTemporaryLayoffs(1, account, true)[0];
        Test.stopTest();
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_237'];
        TemporaryLayoff__c insertedTemporaryLayoff = [SELECT OwnerId, NAV_Unit__c FROM TemporaryLayoff__c LIMIT 1];
        System.assertEquals(queue.Id, insertedTemporaryLayoff.OwnerId);
        System.assertEquals(null, insertedTemporaryLayoff.NAV_Unit__c);
    }

    @IsTest
    private static void insertWhenNoMatchingSharingRule_whenNoMatchingRules() {
        Account account = TAG_TestDataFactory.createAccounts(1)[0];
        account.INT_MunicipalityNumber__c = '9999';
        update account;

        Test.startTest();
        TAG_TestDataFactory.getTemporaryLayoffs(1, account, true);
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM TemporaryLayoff__c LIMIT 1].OwnerId);
    }

    @IsTest
    private static void insertWhenPostalCodeRouting() {
        NavUnit__c navUnit = TestDataFactory.getNavUnits(1, false)[0];
        navUnit.INT_UnitNumber__c = '5702';
        navUnit.Name = 'NAV Lerkendal';
        insert navUnit;

        Account account = TAG_TestDataFactory.createAccounts(1)[0];
        account.INT_MunicipalityNumber__c = '5001';
        account.ShippingPostalCode = '7078';
        update account;

        Test.startTest();
        TemporaryLayoff__c temporaryLayoff = TAG_TestDataFactory.getTemporaryLayoffs(1, account, true)[0];
        Test.stopTest();

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_5702'];
        TemporaryLayoff__c insertedTemporaryLayoff = [SELECT OwnerId, NAV_Unit__c FROM TemporaryLayoff__c LIMIT 1];
        System.assertEquals(queue.Id, insertedTemporaryLayoff.OwnerId);
        System.assertEquals(navUnit.Id, insertedTemporaryLayoff.NAV_Unit__c);
    }
}