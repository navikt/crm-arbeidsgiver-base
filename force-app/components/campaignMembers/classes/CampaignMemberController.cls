public with sharing class CampaignMemberController {
    @AuraEnabled(cacheable=true)
    public static List<CustomCampaignMember__c> getData(Id recordId) {
        List<CustomCampaignMember__c> ccm = [
            SELECT
                Id,
                Name,
                Account__r.Name,
                Status__c
            FROM CustomCampaignMember__c
            WHERE CustomCampaign__c = :recordId
        ];

        return ccm;
    }
    @AuraEnabled
    public static void deleteCampaignMember(Id recordId) {
        CustomCampaignMember__c recordToDelete = [SELECT Id FROM CustomCampaignMember__c WHERE Id = :recordId];
        delete recordToDelete;
    }
}
