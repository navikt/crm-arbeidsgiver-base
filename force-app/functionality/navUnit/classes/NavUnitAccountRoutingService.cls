public without sharing class NavUnitAccountRoutingService {
    public static List<Account> getNavUnits(List<Account> accounts) {
        List<SobjectWrapper> sobjects = getSobjectWrappers(accounts);
        Map<Integer, ApexSharingRuleWrapper> ruleByByAccountId = RecordOwnerService.getQueuesAndNavUnits(
            sobjects,
            'TemporaryLayoff__c'
        );
        Integer i = 0;
        for (Account acc : accounts) {
            ApexSharingRuleWrapper rule = ruleByByAccountId.get(i);
            if (rule == null)
                continue;
            acc.TAG_NavUnit__c = rule.navUnitId;
            i++;
        }

        return accounts;
    }

    private static List<SobjectWrapper> getSobjectWrappers(
        List<Account> accounts
    ) {
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer i = 0;
        for (Account acc : accounts) {
            SobjectWrapper wrapper = new SobjectWrapper();
            wrapper.RecordIndex = i;
            wrapper.Municipality = acc.INT_MunicipalityNumber__c;
            wrapper.PostalCode = acc.ShippingPostalCode;
            i++;
            wrappers.add(wrapper);
        }

        return wrappers;
    }
}
