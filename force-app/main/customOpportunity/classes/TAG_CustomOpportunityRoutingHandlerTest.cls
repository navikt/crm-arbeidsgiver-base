@IsTest
private class TAG_CustomOpportunityRoutingHandlerTest {

    @TestSetup
    private static void setupTestData(){
        TestDataFactory.getQueue('NAV Farsund', 'queue_1003', 'CustomOpportunity__c');
    }

    @IsTest
    private static void insertCustomOpportunity(){
        CustomOpportunity__c customOpportunity=TAG_TestDataFactory.getCustomOpportunities(1);
        customOpportunity.INT_MunicipalityNumber__c='4206';

        Test.startTest();
        insert customOpportunity;
        Test.stopTest();
        Group queue=[SELECT Id FROM Group WHERE DeveloperName='queue_1003'];
        System.assertEquals(queue.Id, [SELECT OwnerId FROM CustomOpportunity__c LIMIT 1].OwnerId);
    }

    @IsTest
    private static void insertWhenNoMatchingSharingRule(){
        CustomOpportunity__c customOpportunity=TAG_TestDataFactory.getCustomOpportunities(1);
        customOpportunity.INT_MunicipalityNumber__c='999988';

        Test.startTest();
        insert customOpportunity;
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM CustomOpportunity__c LIMIT 1].OwnerId);
    }
}