global class TAG_CustomOpportunityRoutingHandler extends MyTriggers {
    global override void onBeforeInsert() {
        Map<Integer, ApexSharingRuleWrapper> ruleByByOpportunityId = RecordOwnerService.getQueuesAndNavUnits(
            getSobjectWrappers(),
            'CustomOpportunity__c'
        );
        Integer i = 0;
        for (CustomOpportunity__c opportunity : (List<CustomOpportunity__c>) records) {
            ApexSharingRuleWrapper rule = ruleByByOpportunityId.get(i);
            if (rule == null)
                continue;
            opportunity.OwnerId = rule.queueId;
            opportunity.TAG_NavUnit__c = rule.navUnitId;
            i++;
        }
    }

    private List<SobjectWrapper> getSobjectWrappers() {
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer recordIndex = 0;
        for (CustomOpportunity__c opportunity : (List<CustomOpportunity__c>) records) {
            wrappers.add(
                new SobjectWrapper(recordIndex, opportunity.INT_MunicipalityNumber__c, opportunity.INT_RegionNumber__c)
            );
            recordIndex++;
        }

        return wrappers;
    }
}