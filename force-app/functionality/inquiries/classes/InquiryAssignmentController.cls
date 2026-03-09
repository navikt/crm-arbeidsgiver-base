public without sharing class InquiryAssignmentController {
    /*

    @AuraEnabled
    public static void assignToCurrentUser(Id recordId) {
        EmployerInquiry__c inquiry = new EmployerInquiry__c(
            Id = recordId,
            OwnerId = UserInfo.getUserId()
        );
        update inquiry;
    }

    */

    @AuraEnabled
    public static void assignToCurrentUser(Id recordId) {
        EmployerInquiry__c inquiry = new EmployerInquiry__c(Id = recordId, OwnerId = UserInfo.getUserId());
        update inquiry;
    }

    @AuraEnabled
    public static void unassignToQueue(Id recordId) {
        EmployerInquiry__c inquiry = [
            SELECT Id, NavUnit__r.CRM_QueueId__c
            FROM EmployerInquiry__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        Id queueId = inquiry.NavUnit__r.CRM_QueueId__c;
        if (queueId == null) {
            throw new AuraHandledException('Queue ID is null or undefined for this inquiry\'s Nav Unit');
        }

        inquiry.OwnerId = queueId;
        update inquiry;
    }
}
