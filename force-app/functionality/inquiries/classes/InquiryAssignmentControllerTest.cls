@IsTest
private class InquiryAssignmentControllerTest {
    @TestSetup
    static void makeData() {
        Group groupNavUnit1 = new Group(Name = 'NAV Test Unit 1', Type = 'Queue');
        insert groupNavUnit1;

        QueuesObject qoNavUnit1 = new QueueSObject(QueueID = groupNavUnit1.id, SObjectType = 'EmployerInquiry__c');
        insert qoNavUnit1;
    }

    @IsTest
    static void getQueueIdForInquiry_returnsQueueId() {
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'NAV Test Unit 1' AND Type = 'Queue' LIMIT 1];
        NavUnit__c navUnit = new NavUnit__c(
            Name = 'NAV Test Unit 1',
            INT_UnitNumber__c = '9997',
            CRM_QueueId__c = testGroup.Id
        );
        insert navUnit;

        EmployerInquiry__c inquiry = new EmployerInquiry__c(TAG_NavUnit__c = navUnit.Id);
        insert inquiry;

        Test.startTest();
        String resultQueueId = InquiryAssignmentController.getQueueIdForInquiry(inquiry.Id);
        Test.stopTest();

        System.assertEquals(String.valueOf(testGroup.Id), resultQueueId, 'Should return the NavUnit queue ID');
    }

    @IsTest
    static void getQueueIdForInquiry_throwsWhenQueueIdNull() {
        NavUnit__c navUnit = new NavUnit__c(Name = 'NAV No Queue 2', INT_UnitNumber__c = '9996');
        insert navUnit;

        EmployerInquiry__c inquiry = new EmployerInquiry__c(TAG_NavUnit__c = navUnit.Id);
        insert inquiry;

        Test.startTest();
        try {
            InquiryAssignmentController.getQueueIdForInquiry(inquiry.Id);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Error message should not be null');
        }
        Test.stopTest();
    }
}
