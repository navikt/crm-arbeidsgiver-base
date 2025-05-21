/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    // private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    private static final LoggerUtility LOGGER = new LoggerUtility();
    private static Id recordId;
    private static Map<String, String> reportIdMap;

    // Centralized query config
    private static final Map<String, String> QUERY_MAP = new Map<String, String>{
        'Account' => 'SELECT Id, Name, NumberOfWorkfare__c FROM Account WHERE Id = :accountId',
        'CustomOpportunity__c' => 'SELECT Id, InquiryCategory__c, InclusionStage__c FROM CustomOpportunity__c WHERE InclusionStage__c != \'Avsluttet\' AND Account__c = :accountId',
        'Contract__c' => 'SELECT Id, TAG_Category__c FROM Contract__c WHERE RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Account__c = :accountId',
        'JobPosting__c' => 'SELECT Id, Status__c FROM JobPosting__c WHERE Status__c = \'ACTIVE\' AND Account__c = :accountId',
        'IACooperation__c' => 'SELECT Id, Status__c, IACase__c FROM IACooperation__c WHERE Status__c = \'AKTIV\' AND Account__c = :accountId AND (IACase__r.CaseStatus__c IN (\'NY\', \'VURDERES\', \'KONTAKTES\', \'KARTLEGGES\', \'VI_BISTÅR\'))',
        'Workfare__c' => 'SELECT Id, Status__c FROM Workfare__c WHERE Status__c = \'GJENNOMFØRES\' AND Account__c = :accountId'
    };

    // Centralized badge config
    private static final Map<String, Map<String, String>> BADGE_CONFIG = new Map<String, Map<String, String>>{
        'Muligheter' => new Map<String, String>{
            'labelTemplate' => 'Muligheter({0})',
            'helpText' => 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Muligheter'
        },
        'Stillinger' => new Map<String, String>{
            'labelTemplate' => 'Stillinger({0})',
            'helpText' => 'Antall aktive offentlige utlyste- og direktemeldte stillinger.',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Stillinger'
        },
        'Tiltak' => new Map<String, String>{
            'labelTemplate' => 'Tiltak({0})',
            'helpText' => 'Antall aktive tiltak registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Tiltak'
        },
        'IA-samarbeid' => new Map<String, String>{
            'labelTemplate' => 'IA-samarbeid',
            'helpText' => 'Bedriften har IA-samarbeid med Nav.',
            'url' => '/lightning/r/IACooperation__c/{0}/view',
            'badgeType' => 'IA-samarbeid'
        },
        'IA-samarbeid_Avtale' => new Map<String, String>{
            'labelTemplate' => 'IA-samarbeid',
            'helpText' => 'Bedriften har IA-samarbeid med Nav.',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'IA-samarbeid'
        },
        'Strategisk partner' => new Map<String, String>{
            'labelTemplate' => 'Strategisk partner',
            'helpText' => 'Bedriften har strategisk partneravtale med Nav.',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Strategisk partner'
        },
        'Marked-samarbeid' => new Map<String, String>{
            'labelTemplate' => 'Marked-samarbeid',
            'helpText' => 'Bedriften har avtale med tilsvarende kategori.',
            'url' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Marked-samarbeid'
        }
        // Add more badge configs as needed
    };

    // Static map for report names
    private static final Map<String, String> REPORT_NAMES = new Map<String, String>{
        'Muligheter' => 'Muligheter_4WR',
        'Stillinger' => 'Stillinger_adu',
        'Tiltak' => 'Aktive_tiltak_tilknyttet_arbeidsgiver',
        'Avtaler' => 'Avtaler_Zsu'
    };

    /**
     * @description Creates badges for a given account based on its fields and related records.
     * @param accountId The Id of the Account for which to create badges.
     * @return A list of badges created for the account.
     */
    @AuraEnabled(cacheable=true)
    public static List<Badge> createBadges(Id accountId) {
        recordId = accountId;
        List<Badge> accountBadges = new List<Badge>();
        try {
            List<Contract__c> employerAgreements = (List<Contract__c>) fetchRecords(accountId, 'Contract__c');
            List<CustomOpportunity__c> employerOpportunities = (List<CustomOpportunity__c>) fetchRecords(
                accountId,
                'CustomOpportunity__c'
            );
            List<JobPosting__c> employerJobPostings = (List<JobPosting__c>) fetchRecords(accountId, 'JobPosting__c');
            List<IACooperation__c> employerIACooperations = (List<IACooperation__c>) fetchRecords(
                accountId,
                'IACooperation__c'
            );
            List<Workfare__c> employerWorkfares = (List<Workfare__c>) fetchRecords(accountId, 'Workfare__c');

            accountBadges.addAll(createPartnerTypeBadge(employerAgreements, employerIACooperations));
            accountBadges.addAll(createOpportunityCountBadge(employerOpportunities));
            accountBadges.addAll(createJobPostingBadge(employerJobPostings));
            accountBadges.addAll(createWorkfareBadge(employerWorkfares));
        } catch (Exception e) {
            logError(accountId, e);
            return new List<Badge>();
        }
        return accountBadges;
    }

    /**
     * @description Fetches records of a given object type for a specific account.
     * @param accountId The Id of the Account to fetch records for.
     * @param objectName The name of the object to fetch records from.
     * @return A list of records of the specified object type.
     */
    @TestVisible
    private static List<sObject> fetchRecords(Id accountId, String objectName) {
        String query = QUERY_MAP.get(objectName);
        List<sObject> queryResult = new List<sObject>();
        try {
            queryResult = Database.query(query, AccessLevel.USER_MODE);
            return queryResult;
        } catch (QueryException e) {
            logError(accountId, e);
            return new List<sObject>();
        }
    }

    /**
     * @description Logs an error for a given account.
     * @param accountId The Id of the Account for which to log the error.
     * @param e The exception to log.
     */
    private static void logError(Id accountId, Exception e) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            accountId,
            e.getMessage(),
            e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        LOGGER.publish();
    }

    // Helper to create a badge from config
    @TestVisible
    private static Badge createBadgeFromConfig(String key, List<Object> labelMergeFields, List<Object> urlMergeFields) {
        Map<String, String> config = BADGE_CONFIG.get(key);
        if (config == null)
            return null;

        String label = labelMergeFields != null
            ? String.format(config.get('labelTemplate'), labelMergeFields)
            : config.get('labelTemplate');
        String url = urlMergeFields != null ? String.format(config.get('url'), urlMergeFields) : config.get('url');
        return new Badge(label, config.get('helpText'), url, config.get('badgeType'));
    }

    // Static methods to create specific badges

    // Creates badge for Muligheter. Counts open opportunities.
    // Links to report Muligheter_4WR with filter order: AccountId (fv0), InquiryCategory__c(fv1)
    private static List<Badge> createOpportunityCountBadge(List<CustomOpportunity__c> activeOpportunities) {
        List<Badge> badges = new List<Badge>();
        String reportId = getReportId(REPORT_NAMES.get('Muligheter'));

        if (activeOpportunities.size() >= 1) {
            Badge badge = createBadgeFromConfig(
                'Muligheter',
                new List<Object>{ activeOpportunities.size() },
                new List<Object>{ reportId, recordId }
            );
            if (badge != null)
                badges.add(badge);
        }
        return badges;
    }

    // Creates badge for partner status. Display badge for each partner type.
    /* TAG_Category__c
     * IA-samarbeid - enten avtale eller samarbeid
     * Strategisk partner - har Strategisk partneravtale
     * Marked-samarbeid - har avtale med tilsvarende kategori
     */
    private static List<Badge> createPartnerTypeBadge(
        List<Contract__c> employerAgreements,
        List<IACooperation__c> iaCooperations
    ) {
        Map<String, Badge> badges = new Map<String, Badge>();
        Set<String> partnerStatuses = new Set<String>();
        String reportId = getReportId(REPORT_NAMES.get('Avtaler'));

        for (Contract__c con : employerAgreements) {
            if (!String.isBlank(con.TAG_Category__c)) {
                partnerStatuses.add(con.TAG_Category__c);
            }
        }

        // Check if there are any IA cooperations and add IA cooperation badge if so
        if (iaCooperations.size() >= 1) {
            Badge badge = createBadgeFromConfig('IA-samarbeid', null, new List<Object>{ iaCooperations[0].IACase__c });
            badges.put(badge.label, badge);
        } else if (partnerStatuses.contains('IA-samarbeid')) {
            Badge badge = createBadgeFromConfig(
                'IA-samarbeid_Avtale',
                null,
                new List<Object>{ reportId, recordId, 'IA-samarbeid' }
            );
            badges.put(badge.label, badge);
        }
        // Create badges for Contracts
        if (partnerStatuses.contains('Strategisk partneravtale')) {
            Badge badge = createBadgeFromConfig(
                'Strategisk partner',
                null,
                new List<Object>{ reportId, recordId, 'Strategisk partner' }
            );
            badges.put(badge.label, badge);
        }
        if (partnerStatuses.contains('Marked-samarbeid')) {
            Badge badge = createBadgeFromConfig(
                'Marked-samarbeid',
                null,
                new List<Object>{ reportId, recordId, 'Marked-samarbeid' }
            );
            badges.put(badge.label, badge);
        }
        return badges.values();
    }

    // Creates badge for job postings at employer.
    private static List<Badge> createJobPostingBadge(List<JobPosting__c> jobPostings) {
        List<Badge> badges = new List<Badge>();
        String reportId = getReportId(REPORT_NAMES.get('Stillinger'));
        if (jobPostings.size() >= 1) {
            Badge badge = createBadgeFromConfig(
                'Stillinger',
                new List<Object>{ jobPostings.size() },
                new List<Object>{ reportId, recordId }
            );
            if (badge != null)
                badges.add(badge);
        }
        return badges;
    }

    // Creates badge for workfare at employer.
    private static List<Badge> createWorkfareBadge(List<Workfare__c> workfares) {
        List<Badge> badges = new List<Badge>();
        String reportId = getReportId(REPORT_NAMES.get('Tiltak'));
        if (workfares.size() >= 1) {
            Badge badge = createBadgeFromConfig(
                'Tiltak',
                new List<Object>{ workfares.size() },
                new List<Object>{ reportId, recordId }
            );
            if (badge != null)
                badges.add(badge);
        }
        return badges;
    }

    // Helper methods

    // Returns report Id from static map or queries report records
    private static string getReportId(String reportDeveloperName) {
        // Return from static map if exist
        if (reportIdMap != null && !String.isEmpty(reportIdMap.get(reportDeveloperName))) {
            return reportIdMap.get(reportDeveloperName);
        }
        // If prod environment, set map from custom metadata and return value or null
        reportIdMap = new Map<String, String>();
        if (UserInfo.getOrganizationId() == '00D2o000000aANVEA2') {
            for (TAG_BadgeConfiguration__mdt rc : [
                SELECT DeveloperName, Value__c
                FROM TAG_BadgeConfiguration__mdt
            ]) {
                reportIdMap.put(rc.DeveloperName, rc.Value__c);
            }
            if (!String.isEmpty(reportIdMap.get(reportDeveloperName))) {
                return reportIdMap.get(reportDeveloperName);
            } else {
                return null;
            }
        } else {
            // If any other environment, set map by quering report records and return value or null
            List<String> developerNames = new List<String>{
                'Muligheter_4WR',
                'Aktive_tiltak_tilknyttet_arbeidsgiver',
                'Aktive_Tiltaksavtaler_per_Virksomhet',
                'Avtaler_Zsu',
                'Stillinger_adu'
            };
            for (Report r : [
                SELECT Id, DeveloperName
                FROM Report
                WHERE DeveloperName IN :developerNames
            ]) {
                reportIdMap.put(r.DeveloperName, r.Id);
            }
            if (!String.isEmpty(reportIdMap.get(reportDeveloperName))) {
                return reportIdMap.get(reportDeveloperName);
            } else {
                return null;
            }
        }
    }

    // Wrapper class for badge
    public class Badge {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String helpText;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public String urlTooltip = 'Se mer informasjon';
        @AuraEnabled
        public String badgeType;

        public Badge(String label, String helpText, String url, String badgeType) {
            this.label = label;
            this.helpText = helpText;
            this.url = url;
            this.badgeType = badgeType;
        }
    }
}
