// ---- INPUT ----
Id oldCampaignId = '';
Id newCampaignId = '';
// ---------------

CustomCampaign__c newCampaign = [SELECT Id, Name, Type__c FROM CustomCampaign__c WHERE Id = :newCampaignId];

List<CustomCampaignMember__c> membersToMove = [
    SELECT Id
    FROM CustomCampaignMember__c
    WHERE CustomCampaign__c = :oldCampaignId
];

for (CustomCampaignMember__c member : membersToMove) {
    member.CustomCampaign__c = newCampaignId;
    member.Campaign_type__c = newCampaign.Type__c;
    member.Status__c = 'Ny';
    member.Kommentar__c = null;
}

update membersToMove;

System.debug('Moved ' + membersToMove.size() + ' campaign members to ' + newCampaign.Name);
