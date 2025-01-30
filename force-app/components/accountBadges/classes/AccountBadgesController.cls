/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    private static final LoggerUtility logger = new LoggerUtility();

    /**
     * @description Creates badges for a given account based on its fields and related records.
     * @param accountId The Id of the Account for which to create badges.
     * @return A list of badges created for the account.
     */
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        List<Badge> accountBadges = new List<Badge>();
        try {
            List<Contract__c> employerAgreements = fetchEmployerAgreements(accountId);
            addContractBadges(accountBadges, employerAgreements);

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
            WHERE Id = :accountId AND IsPersonAccount = FALSE
        ];
    }
    /**
     * @description Fetches Contract records.
     * @param accountId The Id of the Account to fetch contracts for.
     * @return List of Contract__c records.
     */
    private static List<Contract__c> fetchEmployerAgreements(Id accountId) {
        return [
            SELECT Region__c, TAG_Category__c, TAG_Type_Partner__c
            FROM Contract__c
            WHERE
                RecordType.DeveloperName = 'EmployerAgreement'
                AND TAG_Status__c = 'Godkjent'
                AND TAG_EndDate__c > TODAY
                AND TAG_StartDate__c <= TODAY
                AND TAG_Account__c = :accountId
        ];
    }

    /**
     * @description Adds badges to the accountBadges list based on the Account fields.
     * @param accountBadges The list of badges to add to.
     * @param account The Account record to evaluate.
     */
    private static void addAccountBadges(List<Badge> accountBadges, Account account) {
        if (AccessControlValidator.fieldIsAccessible('Account', 'NumberOfWorkfare__c')) {
            accountBadges.addAll(createNumberOfWorkfareBadge(account));
        }
    }

    /**
     * @description Adds badges to the accountBadges list based on the related CustomOpportunity__c records.
     * @param accountBadges The list of badges to add to.
     * @param opportunities The related CustomOpportunity__c records to evaluate.
     */
    private static void addOpportunityBadges(
        List<Badge> accountBadges,
        List<CustomOpportunity__c> activeOpportunities
    ) {
        accountBadges.addAll(createOpportunityCountBadge(activeOpportunities));
    }

    /**
     * @description Adds badges to the accountBadges list based on the related Contract__c records.
     * @param accountBadges The list of badges to add to.
     * @param employerAgreements The related Contract__c records to evaluate.
     */
    private static void addContractBadges(List<Badge> accountBadges, List<Contract__c> employerAgreements) {
        if (
            AccessControlValidator.fieldIsAccessible('Contract__c', 'Region__c') &&
            AccessControlValidator.fieldIsAccessible('Contract__c', 'TAG_Category__c')
        ) {
            accountBadges.addAll(createAgreementBadges(employerAgreements));
        }

        if (AccessControlValidator.fieldIsAccessible('Contract__c', 'TAG_Type_Partner__c')) {
            accountBadges.addAll(createPartnerTypeBadge(employerAgreements));
        }
    }

    /**
     * @description Logs an error for a given account.
     * @param accountId The Id of the Account for which to log the error.
     * @param e The exception to log.
     */
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

    // Static methods to create specific badges

    private static List<Badge> createNumberOfWorkfareBadge(Account account) {
        String labelTemplate = 'Aktive Tiltak({0})';
        String helpText = accountFields.get('NumberOfWorkfare__c').getDescribe().getInlineHelpText();
        Map<String, Badge> badges = new Map<String, Badge>();
        if (account.NumberOfWorkfare__c >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ account.NumberOfWorkfare__c });
            Badge badge = new Badge(label, helpText);
            badges.put(label, badge);
        }
        return badges.values();
    }

    private static List<Badge> createOpportunityCountBadge(List<CustomOpportunity__c> activeOpportunities) {
        String labelTemplate = 'Muligheter({0})';
        String helpText = 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".';
        Map<String, Badge> badges = new Map<String, Badge>();
        if (activeOpportunities.size() >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ activeOpportunities.size() });
            Badge badge = new Badge(label, helpText);
            badges.put(label, badge);
        }
        return badges.values();
    }

    private static List<Badge> createAgreementBadges(List<Contract__c> employerAgreements) {
        String labelTemplate = '{0} {1}';
        String helpText = 'Bedriften har aktiv samarbeidsavtale innen angitt region og kategori.';
        Map<String, Badge> badges = new Map<String, Badge>();
        for (Contract__c employerAgreement : employerAgreements) {
            if (!String.isBlank(employerAgreement.Region__c) && !String.isBlank(employerAgreement.TAG_Category__c)) {
                String category = employerAgreement.TAG_Category__c.replaceAll('\\(.*\\)', '').trim();
                String label = String.format(labelTemplate, new List<Object>{ employerAgreement.Region__c, category });
                Badge badge = new Badge(label, helpText);
                badges.put(label, badge);
            }
        }
        return badges.values();
    }

    private static List<Badge> createPartnerTypeBadge(List<Contract__c> employerAgreements) {
        String labelTemplate = '{0}';
        String helpText = 'Denne bedriftens partnerstatus basert på aktive avtaler.';
        Map<String, Badge> badges = new Map<String, Badge>();
        for (Contract__c employerAgreement : employerAgreements) {
            if (!String.isBlank(employerAgreement.TAG_Type_Partner__c)) {
                String label = String.format(labelTemplate, new List<Object>{ employerAgreement.TAG_Type_Partner__c });
                Badge badge = new Badge(label, helpText);
                badges.put(label, badge);
            }
        }
        return badges.values();
    }

    public class Badge {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String helpText;
        public Badge(String label, String helpText) {
            this.label = label;
            this.helpText = helpText;
        }
    }
}
