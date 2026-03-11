@IsTest
private class InquiryAssignmentControllerTest {
    @IsTest
    static void getQueueIdForInquiry_returnsQueueId() {
        Group testQueue = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];

        NavUnit__c navUnit = new NavUnit__c(
            Name = 'NAV Test Unit 2',
            INT_UnitNumber__c = '9997',
            CRM_QueueId__c = testQueue.Id
        );
        insert navUnit;

        EmployerInquiry__c inquiry = new EmployerInquiry__c(TAG_NavUnit__c = navUnit.Id);
        insert inquiry;

        Test.startTest();
        String queueId = InquiryAssignmentController.getQueueIdForInquiry(inquiry.Id);
        Test.stopTest();

        System.assertEquals(String.valueOf(testQueue.Id), queueId, 'Should return the NavUnit queue ID');
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
