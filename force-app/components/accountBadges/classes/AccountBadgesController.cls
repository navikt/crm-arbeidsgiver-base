public with sharing class AccountBadgesController {
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        // Sample data
        /*
        accountBadges.add(new Badge('yellow','Sample1','Sample1 description'));
        accountBadges.add(new Badge('pink','Sample2','Sample2 description'));
        accountBadges.add(new Badge('orange','Sample3','Sample3 description'));
        System.debug(accountBadges);
       */
        try {
            Account account = [SELECT TAG_Partner_Status__c FROM Account WHERE Id = :accountId];

            addParterStatusBadge(accountBadges, account);
        } catch (Exception e) {
            throw new AuraHandledException('Something went wrong: ' + e.getMessage());
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
