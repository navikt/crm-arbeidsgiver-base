public with sharing class AccountBadgesController {
    private static final LoggerUtility logger = new LoggerUtility();

    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        try {
            Account account = fetchAccount(accountId);
            addAccountBadges(accountBadges, account);
            addOpportunityBadges(accountBadges, account);
        } catch (Exception e) {
            logError(accountId, e);
            return new List<Badge>();
        }
        return accountBadges;
    }

    private static Account fetchAccount(Id accountId) {
        return [
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
    }

    private static void addAccountBadges(List<Badge> accountBadges, Account account) {
        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'TAG_Partner_Status__c',
            account.TAG_Partner_Status__c,
            'Partner status',
            !String.isBlank(account.TAG_Partner_Status__c)
        );

        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'TAG_FiaCaseStatus__c',
            account.TAG_FiaCaseStatus__c,
            '',
            account.TAG_FiaCaseStatus__c == 'VI_BISTÅR'
        );
        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'NumberOfWorkfare__c',
            account.NumberOfWorkfare__c + ' aktive tiltak',
            '',
            true
        );
    }

    private static void addOpportunityBadges(List<Badge> accountBadges, Account account) {
        if (!AccessControlValidator.sObjectIsAccessible('CustomOpportunity__c')) {
            return;
        }

        List<CustomOpportunity__c> opportunities = account.Inkluderingsmuligheter__r;
        Integer newOpportunitiesCount = countOpportunities(opportunities, 'Ny henvendelse');
        Integer openForCanidatesCount = countOpportunities(opportunities, 'Åpen for kandidater');

        addBadge(accountBadges, opportunities.size() + ' åpne muligheter', '');

        addBadgeIfAccessible(
            accountBadges,
            'CustomOpportunity__c',
            'InclusionStage__c',
            newOpportunitiesCount + ' nye henvendelser',
            '',
            opportunities.size() > 0
        );

        addBadgeIfAccessible(
            accountBadges,
            'CustomOpportunity__c',
            'InclusionStage__c',
            'Åpen for kandidater!',
            '',
            opportunities.size() > 0 && openForCanidatesCount > 0
        );
    }

    private static void addBadgeIfAccessible(
        List<Badge> accountBadges,
        String sObjectType,
        String fieldName,
        String label,
        String helpText,
        Boolean condition
    ) {
        if (AccessControlValidator.fieldIsAccessible(sObjectType, fieldName) && condition) {
            accountBadges.add(new Badge(label, helpText));
        }
    }

    private static void addBadge(List<Badge> accountBadges, String label, String helpText) {
        accountBadges.add(new Badge(label, helpText));
    }

    private static Integer countOpportunities(List<CustomOpportunity__c> opportunities, String stage) {
        Integer count = 0;
        for (CustomOpportunity__c opp : opportunities) {
            if (opp.InclusionStage__c == stage) {
                count++;
            }
        }
        return count;
    }

    private static void logError(Id accountId, Exception e) {
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
