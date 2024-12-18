public with sharing class AccountBadgesController {
    private static final LoggerUtility logger = new LoggerUtility();
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        try {
            Account account = [SELECT TAG_Partner_Status__c FROM Account WHERE Id = :accountId];
            addParterStatusBadge(accountBadges, account);
        } catch (Exception e) {
            logger.logMessage(
                LoggerUtility.LogLevel.Error,
                '',
                accountId,
                e.getMessage(),
                e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.POAB
            );
            logger.publish();
            return new List<Badge>();
        }
        return accountBadges;
    }

    private static void addParterStatusBadge(List<Badge> accountBadges, Account account) {
        if (AccessControlValidator.fieldIsAccessible('Account', 'TAG_Partner_Status__c')) {
            if (
                account.TAG_Partner_Status__c == 'Strategisk partner' ||
                account.TAG_Partner_Status__c == 'Samarbeidspartner'
            ) {
                accountBadges.add(new Badge(account.TAG_Partner_Status__c, 'Partner status'));
            }
        }
    }

    public class Badge {
        public Badge(String label, String helpText) {
            this.label = label;
            this.helpText = helpText;
        }
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String helpText;
    }
}
