global class TAG_TemporaryLayoffRoutingHandler extends MyTriggers {

    global override void onBeforeInsert() {

        Map<Integer, ApexSharingRuleWrapper> ruleByByLayoffId = RecordOwnerService.getQueuesAndNavUnits(getSobjectWrappers(), 'TemporaryLayoff__c');
        Integer i=0;
        for (TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records) {
            ApexSharingRuleWrapper rule = ruleByByLayoffId.get(0);
            if (rule == null) continue;
            layoff.OwnerId = rule.queueId;
            layoff.Nav_Unit__c = rule.navUnitId;
            i++;
        }
    }

    private List<SobjectWrapper> getSobjectWrappers() {
        Map<Id, String> municipalityNumberByAccountId = getMunicipalityNumberByAccountId();
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer recordIndex=0;
        for (TemporaryLayoff__c layoff : (List<TemporaryLayoff__c>) records) {
            wrappers.add(new SobjectWrapper(recordIndex, municipalityNumberByAccountId.get(layoff.Account__c)));
            recordIndex++;
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