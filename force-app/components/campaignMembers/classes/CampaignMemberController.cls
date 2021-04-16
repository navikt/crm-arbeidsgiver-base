public with sharing class CampaignMemberController {
    @AuraEnabled(cacheable=true)
    public static List<CustomCampaignMember__c> getData(Id recordId) {
        List<CustomCampaignMember__c> actm = [
            SELECT
                Id,
                Name,
                Account__r.Name,
                Status__c
            FROM CustomCampaignMember__c
            WHERE CustomCampaign__c = :recordId
        ];

        return actm;
    }
}
