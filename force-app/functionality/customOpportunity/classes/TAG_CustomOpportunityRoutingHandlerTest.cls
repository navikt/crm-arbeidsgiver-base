@IsTest
public class TAG_CustomOpportunityRoutingHandlerTest {
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('NAV Lister', 'queue_1037', 'CustomOpportunity__c');
        TestDataFactory.getQueue('NAV Eidsvoll', 'queue_237', 'CustomOpportunity__c');
    }

    @IsTest
    private static void insertCustomOpportunity() {
        NavUnit__c navUnit = TestDataFactory.getNavUnits(1, false)[0];
        navUnit.INT_UnitNumber__c = '1037';
        insert navUnit;
        CustomOpportunity__c customOpportunity = TAG_TestDataFactory.getCustomOpportunities(
            1,
            false
        )[0];
        customOpportunity.INT_MunicipalityNumber__c = '4206';

        Test.startTest();
        insert customOpportunity;
        Test.stopTest();
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_1037'];
        CustomOpportunity__c insertedCustomOpportunity = [
            SELECT OwnerId, TAG_NavUnit__c
            FROM CustomOpportunity__c
            LIMIT 1
        ];
        System.assertEquals(queue.Id, insertedCustomOpportunity.OwnerId);
        System.assertEquals(navUnit.Id, insertedCustomOpportunity.TAG_NavUnit__c);
    }

    @IsTest
    private static void insertCustomOpportunity_whenMatchingQueueButNoMatchingNavUnit() {
        CustomOpportunity__c customOpportunity = TAG_TestDataFactory.getCustomOpportunities(
            1,
            false
        )[0];
        customOpportunity.INT_MunicipalityNumber__c = '3035';

        Test.startTest();
        insert customOpportunity;
        Test.stopTest();
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_237'];
        CustomOpportunity__c insertedCustomOpportunity = [
            SELECT OwnerId, TAG_NavUnit__c
            FROM CustomOpportunity__c
            LIMIT 1
        ];
        System.assertEquals(queue.Id, insertedCustomOpportunity.OwnerId);
        System.assertEquals(null, insertedCustomOpportunity.TAG_NavUnit__c);
    }
    @IsTest
    private static void insertWhenNoMatchingSharingRule_whenNoMatchingRules() {
        CustomOpportunity__c customOpportunity = TAG_TestDataFactory.getCustomOpportunities(
            1,
            false
        )[0];
        customOpportunity.INT_MunicipalityNumber__c = '999988';

        Test.startTest();
        insert customOpportunity;
        Test.stopTest();

        System.assertEquals(
            UserInfo.getUserId(),
            [SELECT OwnerId FROM CustomOpportunity__c LIMIT 1]
            .OwnerId
        );
    }
}
