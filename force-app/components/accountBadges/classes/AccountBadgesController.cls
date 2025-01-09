public with sharing class AccountBadgesController {
    private static final LoggerUtility logger = new LoggerUtility();
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        try {
            Account account = [
                SELECT
                    TAG_Partner_Status__c,
                    NumberOfWorkfare__c,
                    TAG_FiaCaseStatus__c,
                    (
                        SELECT Id, InquiryCategory__c, InclusionStage__c
                        FROM Inkluderingsmuligheter__r
                        WHERE InclusionStage__c != 'Avsluttet'
                        LIMIT 1000
                    )
                FROM Account
                WHERE Id = :accountId
            ];
            if (account == null) {
                return new List<Badge>();
            }
            addAccountBadges(accountBadges, account);

            if (AccessControlValidator.sObjectIsAccessible('CustomOpportunity__c')) {
                List<CustomOpportunity__c> activeOpportunities = account.Inkluderingsmuligheter__r;
                addOpportunityBadges(accountBadges, activeOpportunities);
            }
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

    private static void addAccountBadges(List<Badge> accountBadges, Account account) {
        //addParterStatusBadge
        if (AccessControlValidator.fieldIsAccessible('Account', 'TAG_Partner_Status__c')) {
            if (
                account.TAG_Partner_Status__c == 'Strategisk Partner' ||
                account.TAG_Partner_Status__c == 'Samarbeidspartner'
            ) {
                accountBadges.add(new Badge(account.TAG_Partner_Status__c, 'Partner status'));
            }
        }
        //addIAStatusBadge
        if (AccessControlValidator.fieldIsAccessible('Account', 'TAG_FiaCaseStatus__c')) {
            if (account.TAG_FiaCaseStatus__c == 'VI_BISTÅR') {
                accountBadges.add(new Badge(account.TAG_FiaCaseStatus__c, ''));
            }
        }
        //addNumberOfWorkfareBadge
        if (AccessControlValidator.fieldIsAccessible('Account', 'NumberOfWorkfare__c')) {
            String badgeLabel = account.NumberOfWorkfare__c + ' aktive tiltak';
            String badgeHelpText = '';
            accountBadges.add(new Badge(badgeLabel, badgeHelpText));
        }
    }

    private static void addOpportunityBadges(List<Badge> accountBadges, List<CustomOpportunity__c> opportunities) {
        //addActiveOpportunitiesBadge
        Integer opportunitiesCount = opportunities == null ? 0 : opportunities.size();
        accountBadges.add(new Badge(opportunitiesCount + ' åpne muligheter', ''));

        if (AccessControlValidator.fieldIsAccessible('CustomOpportunity__c', 'InclusionStage__c')) {
            Integer newOpportunitiesCount = 0;
            Integer openForCanidatesCount = 0;
            for (CustomOpportunity__c opp : opportunities) {
                if (opp.InclusionStage__c == 'Ny henvendelse') {
                    newOpportunitiesCount++;
                } else if (opp.InclusionStage__c == 'Åpen for kandidater') {
                    openForCanidatesCount++;
                }
            }
            //addNewOpportunitiesBadge
            accountBadges.add(new Badge(newOpportunitiesCount + ' nye muligheter', ''));

            //addOpenForCanidatesBadge
            if (openForCanidatesCount > 0) {
                accountBadges.add(new Badge('Åpen for kandidater!', ''));
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
