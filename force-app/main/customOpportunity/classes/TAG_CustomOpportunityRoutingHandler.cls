global class TAG_CustomOpportunitiesRoutingHandler extends MyTriggers{

    global override void onBeforeInsert() {

        Map<Id,ApexSharingRuleWrapper> ruleByByOpportunityId=RecordOwnerService.getQueuesAndNavUnits(getSobjectWrappers(),'CustomOpportunity__c');
        for(CustomOpportunity__c opportunity:(List<CustomOpportunity__c>)records){
            ApexSharingRuleWrapper rule=ruleByByOpportunityId.get(opportunity.Id);
            if(rule==null) continue;
            opportunity.OwnerId=rule.queueId;
        }
    }

    private List<SobjectWrapper> getSobjectWrappers(){
        List<SobjectWrapper> wrappers=new List<SobjectWrapper>();
        for(CustomOpportunity__c opportunity:(List<CustomOpportunity__c>) records){
            wrappers.add(new SobjectWrapper(opportunity.Id,opportunity.INT_MunicipalityNumber__c,opportunity.INT_RegionNumber__c));
        }
        return wrappers;
    }
}