@IsTest
private class InquiryAssignmentControllerTest {
    @IsTest
    static void assignToCurrentUser_setsOwnerToRunningUser() {
        EmployerInquiry__c inquiry = new EmployerInquiry__c();
        insert inquiry;

        Test.startTest();
        InquiryAssignmentController.assignToCurrentUser(inquiry.Id);
        Test.stopTest();

        EmployerInquiry__c result = [SELECT OwnerId FROM EmployerInquiry__c WHERE Id = :inquiry.Id];
        System.assertEquals(UserInfo.getUserId(), result.OwnerId, 'OwnerId should be set to running user');
    }

    @IsTest
    static void unassignToQueue_setsOwnerToNavUnitQueue() {
        Group testQueue = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];

        NavUnit__c navUnit = new NavUnit__c(
            Name = 'NAV Test Unit',
            INT_UnitNumber__c = '9999',
            CRM_QueueId__c = testQueue.Id
        );
        insert navUnit;

        EmployerInquiry__c inquiry = new EmployerInquiry__c(NavUnit__c = navUnit.Id);
        insert inquiry;

        Test.startTest();
        InquiryAssignmentController.unassignToQueue(inquiry.Id);
        Test.stopTest();

        EmployerInquiry__c result = [SELECT OwnerId FROM EmployerInquiry__c WHERE Id = :inquiry.Id];
        System.assertEquals(testQueue.Id, result.OwnerId, 'OwnerId should be set to the NavUnit queue');
    }

    @IsTest
    static void unassignToQueue_throwsWhenQueueIdNull() {
        NavUnit__c navUnit = new NavUnit__c(Name = 'NAV No Queue', INT_UnitNumber__c = '9998');
        insert navUnit;

        EmployerInquiry__c inquiry = new EmployerInquiry__c(NavUnit__c = navUnit.Id);
        insert inquiry;

        Test.startTest();
        try {
            InquiryAssignmentController.unassignToQueue(inquiry.Id);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Error message should not be null');
        }
        Test.stopTest();
    }
}
