// Henter kø-ID for en henvendelses Nav-enhet, slik at henvendelsen kan legges tilbake i køen (fjerne tildeling).
// Kalles fra LWC: inquiryUnassignment
// Avhengigheter: EmployerInquiry__c.TAG_NavUnit__c -> NavUnit__c.CRM_QueueId__c
public with sharing class InquiryAssignmentController {
    @AuraEnabled
    public static String getQueueIdForInquiry(Id recordId) {
        List<EmployerInquiry__c> inquiries = [
            SELECT Id, TAG_NavUnit__r.CRM_QueueId__c
            FROM EmployerInquiry__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (inquiries.isEmpty()) {
            throw new AuraHandledException('Inquiry not found');
        }

        Id queueId = inquiries[0].TAG_NavUnit__r?.CRM_QueueId__c;
        if (queueId == null) {
            throw new AuraHandledException('Queue ID is null for this inquiry\'s Nav Unit');
        }

        return queueId;
    }
}
