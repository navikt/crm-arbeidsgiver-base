global class TAG_TemporaryLayoffRoutingHandler extends MyTriggers {

    global override void onBeforeInsert() {

        Map<Id, ApexSharingRuleWrapper> ruleByByLayoffId = RecordOwnerService.getQueuesAndNavUnits(getSobjectWrappers(), 'TemporaryLayoff__c');
        for (TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records) {
            System.debug(ruleByByLayoffId);
            ApexSharingRuleWrapper rule = ruleByByLayoffId.get(layoff.Id);
            System.debug(rule);
            if (rule == null) continue;
            layoff.OwnerId = rule.queueId;
            layoff.Nav_Unit__c = rule.navUnitId;
            System.debug(layoff);
        }
    }

    private List<SobjectWrapper> getSobjectWrappers() {
        Map<Id, String> municipalityNumberByAccountId = getMunicipalityNumberByAccountId();
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        for (TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records) {
            System.debug(layoff.Id);
            System.debug(municipalityNumberByAccountId.get(layoff.Account__c));
            wrappers.add(new SobjectWrapper(layoff.Id, municipalityNumberByAccountId.get(layoff.Account__c)));
        }
        return wrappers;
    }

    private Map<Id, String> getMunicipalityNumberByAccountId() {
        Set<Id> accountIds = new Set<Id>();
        for (TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records) {
            accountIds.add(layoff.Account__c);
        }
        Map<Id, String> municipalityNumberByAccountId = new Map<Id, String>();
        for (Account acc : [SELECT INT_MunicipalityNumber__c FROM Account WHERE Id in:accountIds]) {
            municipalityNumberByAccountId.put(acc.Id, acc.INT_MunicipalityNumber__c);
        }
        return municipalityNumberByAccountId;
    }
}