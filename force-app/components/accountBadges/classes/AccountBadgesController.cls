/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    private static final LoggerUtility LOGGER = new LoggerUtility();
    private static Map<String, String> reportIdMap;

    // Centralized query config
    private static final Map<String, String> QUERY_MAP = new Map<String, String>{
        'CustomOpportunity__c' => 'SELECT Id, InquiryCategory__c, InclusionStage__c FROM CustomOpportunity__c WHERE InclusionStage__c != \'Avsluttet\' AND Account__c = :accountId',
        'JobPosting__c' => 'SELECT Id, Status__c FROM JobPosting__c WHERE Status__c = \'ACTIVE\' AND Account__c = :accountId',
        'Workfare__c' => 'SELECT Id, Status__c FROM Workfare__c WHERE Status__c = \'GJENNOMFØRES\' AND Account__c = :accountId',
        'Contract__c' => 'SELECT Id, TAG_Category__c FROM Contract__c WHERE RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Account__c = :accountId',
        'IACooperation__c' => 'SELECT Id, Status__c, IACase__c FROM IACooperation__c WHERE Status__c = \'AKTIV\' AND Account__c = :accountId AND (IACase__r.CaseStatus__c IN (\'NY\', \'VURDERES\', \'KONTAKTES\', \'KARTLEGGES\', \'VI_BISTÅR\'))',
        'IACase__c' => 'SELECT Id FROM IACase__c WHERE CaseStatus__c = \'VI_BISTÅR\' AND Account__c = :accountId'
    };

    // Centralized badge config
    private static final Map<String, Map<String, String>> BADGE_CONFIG = new Map<String, Map<String, String>>{
        'Muligheter' => new Map<String, String>{
            'labelTemplate' => 'Muligheter({0})',
            'helpText' => 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".',
            'urlTemplate' => '/lightning/r/Report/{0}/view?fv0={1}&fv2=',
            'badgeType' => 'Muligheter'
        },
        'Stillinger' => new Map<String, String>{
            'labelTemplate' => 'Stillinger({0})',
            'helpText' => 'Antall aktive offentlige utlyste- og direktemeldte stillinger.',
            'urlTemplate' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Stillinger'
        },
        'Tiltak' => new Map<String, String>{
            'labelTemplate' => 'Tiltak({0})',
            'helpText' => 'Antall aktive tiltak registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.',
            'urlTemplate' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Tiltak'
        },
        'IA-samarbeid' => new Map<String, String>{
            'labelTemplate' => 'IA-samarbeid({0})',
            'helpText' => 'Antall aktive IA-samarbeid for denne bedriften.',
            'urlTemplate' => '/lightning/r/IACase__c/{0}/view',
            'badgeType' => 'IA-samarbeid'
        },
        'Strategisk partner' => new Map<String, String>{
            'labelTemplate' => 'Strategisk partner',
            'helpText' => 'Bedriften har strategisk partneravtale med Nav.',
            'urlTemplate' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Strategisk partner'
        },
        'Markedssamarbeid' => new Map<String, String>{
            'labelTemplate' => 'Markedssamarbeid',
            'helpText' => 'Bedriften har avtale med tilsvarende kategori.',
            'urlTemplate' => '/lightning/r/Report/{0}/view?fv0={1}',
            'badgeType' => 'Samarbeidsavtale'
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
        if (accountId == null) {
            return new List<Badge>();
        }
        List<Badge> accountBadges = new List<Badge>();
        try {
            accountBadges.addAll(createContractBadges(accountId));
            accountBadges.addAll(createIACooperationBadge(accountId));
            accountBadges.addAll(createOpportunityCountBadge(accountId));
            accountBadges.addAll(createJobPostingBadge(accountId));
            accountBadges.addAll(createWorkfareBadge(accountId));
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
            return new List<sObject>();
        }
    }

    /**
     * @description Create a badge from config
     * @param key The key used for config in BADGE_CONFIG.
     * @param labelMergeFields List of values to use in labelTemplate. If template has no merge fields, this can be null.
     * @param urlMergeFields List of values to use in urlTemplate. If template has no merge fields, this can be null.
     * @return A new badge.
     */
    @TestVisible
    private static Badge createBadgeFromConfig(String key, List<Object> labelMergeFields, List<Object> urlMergeFields) {
        Map<String, String> config = BADGE_CONFIG.get(key);
        if (config == null) {
            return null;
        }

        String label = labelMergeFields != null
            ? String.format(config.get('labelTemplate'), labelMergeFields)
            : config.get('labelTemplate');
        String url = urlMergeFields != null
            ? String.format(config.get('urlTemplate'), urlMergeFields)
            : config.get('urlTemplate');
        return new Badge(label, config.get('helpText'), url, config.get('badgeType'));
    }

    /** Methods to create specific badges */

    private static List<Badge> createOpportunityCountBadge(Id accountId) {
        List<CustomOpportunity__c> employerOpportunities = (List<CustomOpportunity__c>) fetchRecords(
            accountId,
            'CustomOpportunity__c'
        );
        if (employerOpportunities.isEmpty()) {
            return new List<Badge>();
        }
        Badge badge = createBadgeFromConfig(
            'Muligheter',
            new List<Object>{ employerOpportunities.size() },
            new List<Object>{ getReportId('Muligheter'), accountId }
        );
        return new List<Badge>{ badge };
    }

    private static List<Badge> createContractBadges(Id accountId) {
        List<Contract__c> employerAgreements = (List<Contract__c>) fetchRecords(accountId, 'Contract__c');
        if (employerAgreements.isEmpty()) {
            return new List<Badge>();
        }

        Map<String, Badge> badges = new Map<String, Badge>();
        String reportId = getReportId('Avtaler');
        Set<String> partnerStatuses = new Set<String>();

        for (Contract__c con : employerAgreements) {
            if (!String.isBlank(con.TAG_Category__c)) {
                partnerStatuses.add(con.TAG_Category__c);
            }
        }
        if (partnerStatuses.contains('Strategisk partneravtale')) {
            Badge badge = createBadgeFromConfig('Strategisk partner', null, new List<Object>{ reportId, accountId });
            badges.put(badge.label, badge);
        }
        if (partnerStatuses.contains('Markedssamarbeid')) {
            Badge badge = createBadgeFromConfig('Markedssamarbeid', null, new List<Object>{ reportId, accountId });
            badges.put(badge.label, badge);
        }
        return badges.values();
    }

    private static List<Badge> createIACooperationBadge(Id accountId) {
        List<IACooperation__c> employerIACooperations = (List<IACooperation__c>) fetchRecords(
            accountId,
            'IACooperation__c'
        );
        if (employerIACooperations.isEmpty()) {
            return new List<Badge>();
        }

        Badge badge = createBadgeFromConfig(
            'IA-samarbeid',
            new List<Object>{ employerIACooperations.size() },
            new List<Object>{ employerIACooperations[0].IACase__c }
        );
        return new List<Badge>{ badge };
    }

    private static List<Badge> createJobPostingBadge(Id accountId) {
        List<JobPosting__c> employerJobPostings = (List<JobPosting__c>) fetchRecords(accountId, 'JobPosting__c');
        if (employerJobPostings.isEmpty()) {
            return new List<Badge>();
        }
        Badge badge = createBadgeFromConfig(
            'Stillinger',
            new List<Object>{ employerJobPostings.size() },
            new List<Object>{ getReportId('Stillinger'), accountId }
        );
        return new List<Badge>{ badge };
    }

    // Creates badge for workfare at employer.
    private static List<Badge> createWorkfareBadge(Id accountId) {
        List<Workfare__c> employerWorkfares = (List<Workfare__c>) fetchRecords(accountId, 'Workfare__c');
        if (employerWorkfares.isEmpty()) {
            return new List<Badge>();
        }
        Badge badge = createBadgeFromConfig(
            'Tiltak',
            new List<Object>{ employerWorkfares.size() },
            new List<Object>{ getReportId('Tiltak'), accountId }
        );
        return new List<Badge>{ badge };
    }

    /** Helper methods */

    // Returns report Id from static map or queries report records
    private static string getReportId(String key) {
        String reportDeveloperName = REPORT_NAMES.get(key);
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
            List<String> developerNames = REPORT_NAMES.values();
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

    /** Wrapper class for single badge */
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
