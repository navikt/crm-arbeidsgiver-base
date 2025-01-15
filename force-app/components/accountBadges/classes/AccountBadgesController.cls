/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    private static final LoggerUtility logger = new LoggerUtility();

    //Badge labels and help texts
    @testVisible
    private static String PartnerStatusBadgeLabel = '{0}';
    @testVisible
    private static String PartnerStatusBadgeHelpText = 'Denne bedriftens partnerstatus';
    @testVisible
    private static String NumberOfWorkfareBadgeLabel = 'Aktive Tiltak({0})';
    @testVisible
    private static String NumberOfWorkfareBadgeHelpText = accountFields.get('NumberOfWorkfare__c')
        .getDescribe()
        .getInlineHelpText();
    @testVisible
    private static String ActiveOpportunitiesBadgeLabel = 'Muligheter({0})';
    @testVisible
    private static String ActiveOpportunitiesBadgeHelpText = 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".';

    /**
     * @description Creates badges for a given account based on its fields and related CustomOpportunity__c records.
     * @param accountId The Id of the Account for which to create badges.
     * @return A list of badges created for the account.
     */
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        try {
            Account account = fetchAccount(accountId);
            addAccountBadges(accountBadges, account);
            addOpportunityBadges(accountBadges, account.Inkluderingsmuligheter__r);
        } catch (Exception e) {
            logError(accountId, e);
            return new List<Badge>();
        }
        return accountBadges;
    }

    /**
     * @description Fetches an Account record along with related CustomOpportunity__c records.
     * @param accountId The Id of the Account to fetch.
     * @return The Account record with related CustomOpportunity__c records.
     */
    private static Account fetchAccount(Id accountId) {
        return [
            SELECT
                TAG_Partner_Status__c,
                NumberOfWorkfare__c,
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

    /**
     * @description Adds badges to the accountBadges list based on the Account fields.
     * @param accountBadges The list of badges to add to.
     * @param account The Account record to evaluate.
     */
    private static void addAccountBadges(List<Badge> accountBadges, Account account) {
        // Add badges to accountBadges list if they are accessible and the condition is met
        if (
            AccessControlValidator.fieldIsAccessible('Account', 'TAG_Partner_Status__c') &&
            !String.isBlank(account.TAG_Partner_Status__c)
        ) {
            Badge partnerStatusBadge = new Badge(
                String.format(PartnerStatusBadgeLabel, new List<Object>{ account.TAG_Partner_Status__c }),
                PartnerStatusBadgeHelpText
            );
            accountBadges.add(partnerStatusBadge);
        }

        if (
            AccessControlValidator.fieldIsAccessible('Account', 'NumberOfWorkfare__c') &&
            account.NumberOfWorkfare__c >= 1
        ) {
            Badge numberOfWorkfareBadge = new Badge(
                String.format(NumberOfWorkfareBadgeLabel, new List<Object>{ account.NumberOfWorkfare__c }),
                NumberOfWorkfareBadgeHelpText
            );
            accountBadges.add(numberOfWorkfareBadge);
        }
    }

    /**
     * @description Adds badges to the accountBadges list based on the related CustomOpportunity__c records.
     * @param accountBadges The list of badges to add to.
     * @param activeOpportunities The related CustomOpportunity__c records to evaluate.
     */
    private static void addOpportunityBadges(
        List<Badge> accountBadges,
        List<CustomOpportunity__c> activeOpportunities
    ) {
        // Add badges to list if they are accessible and the condition is met
        Integer activeOpportunitiesCount = activeOpportunities.size();
        if (activeOpportunitiesCount >= 1) {
            Badge activeOpportunitiesBadge = new Badge(
                String.format(ActiveOpportunitiesBadgeLabel, new List<Object>{ activeOpportunitiesCount }),
                ActiveOpportunitiesBadgeHelpText
            );
            accountBadges.add(activeOpportunitiesBadge);
        }
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
