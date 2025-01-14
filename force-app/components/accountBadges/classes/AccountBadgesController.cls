public with sharing class AccountBadgesController {
    private static final LoggerUtility logger = new LoggerUtility();

    // Top-level fields
    private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();

    // Child relationship fields
    private static Map<String, Schema.SObjectField> customOpportunityFields = Schema.SObjectType.CustomOpportunity__c.fields.getMap();

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
        //create badges for account
        Badge partnerStatusBadge = new Badge(
            account.TAG_Partner_Status__c,
            accountFields.get('TAG_Partner_Status__c').getDescribe().getInlineHelpText()
        );
        Badge fiaCaseStatusBadge = new Badge(
            account.TAG_FiaCaseStatus__c,
            accountFields.get('TAG_FiaCaseStatus__c').getDescribe().getInlineHelpText()
        );

        Badge numberOfWorkfareBadge = new Badge(
            'Aktive Tiltak: ' + account.NumberOfWorkfare__c,
            accountFields.get('NumberOfWorkfare__c').getDescribe().getInlineHelpText()
        );

        //add badges to accountBadges list if they are accessible and the condition is met
        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'TAG_Partner_Status__c',
            partnerStatusBadge,
            !String.isBlank(account.TAG_Partner_Status__c)
        );
        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'TAG_FiaCaseStatus__c',
            fiaCaseStatusBadge,
            account.TAG_FiaCaseStatus__c != null
        );
        addBadgeIfAccessible(
            accountBadges,
            'Account',
            'NumberOfWorkfare__c',
            numberOfWorkfareBadge,
            account.NumberOfWorkfare__c != null
        );
    }

    private static void addOpportunityBadges(List<Badge> accountBadges, Account account) {
        if (!AccessControlValidator.sObjectIsAccessible('CustomOpportunity__c')) {
            return; // If the user does not have access to the CustomOpportunity__c object, do not add any opportunity badges
        }
        Integer activeOpportunitiesCount = account.Inkluderingsmuligheter__r.size();
        Integer newOpportunitiesCount = countOpportunities(account.Inkluderingsmuligheter__r, 'Ny henvendelse');
        Integer openForCanidatesCount = countOpportunities(account.Inkluderingsmuligheter__r, 'Åpen for kandidater');

        //create badges related to Opportunities
        Badge activeOpportunitiesBadge = new Badge('Åpne Muligheter: ' + activeOpportunitiesCount, '');
        Badge newOpportunitiesBadge = new Badge('Ny Henvendelse!', 'Har minst én mulighet som venter på behandling');
        Badge openForCanidatesBadge = new Badge('Åpen for kandidater!', '');

        //add badges to accountBadges list if they are accessible and the condition is met
        addBadge(accountBadges, activeOpportunitiesBadge, true);
        addBadgeIfAccessible(
            accountBadges,
            'CustomOpportunity__c',
            'InclusionStage__c',
            newOpportunitiesBadge,
            activeOpportunitiesCount > 0 && newOpportunitiesCount > 0
        );
        addBadgeIfAccessible(
            accountBadges,
            'CustomOpportunity__c',
            'InclusionStage__c',
            openForCanidatesBadge,
            activeOpportunitiesCount > 0 && openForCanidatesCount > 0
        );
    }

    private static void addBadgeIfAccessible(
        List<Badge> accountBadges,
        String sObjectType,
        String fieldName,
        Badge badge,
        Boolean condition
    ) {
        if (AccessControlValidator.fieldIsAccessible(sObjectType, fieldName) && condition) {
            accountBadges.add(badge);
        }
    }

    private static void addBadge(List<Badge> accountBadges, Badge badge, Boolean condition) {
        if (condition) {
            accountBadges.add(badge);
        }
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
