/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    private static final LoggerUtility LOGGER = new LoggerUtility();
    private static Id recordId;
    private static Map<String, String> reportIdMap;

    @TestVisible
    private static final Map<String, String> QUERY_MAP = new Map<String, String>{
        'Account' => 'SELECT Id, Name, NumberOfWorkfare__c FROM Account WHERE Id = :accountId',
        'CustomOpportunity__c' => 'SELECT Id, InquiryCategory__c, InclusionStage__c FROM CustomOpportunity__c WHERE InclusionStage__c != \'Avsluttet\' AND Account__c = :accountId',
        'Contract__c' => 'SELECT Id, TAG_Category__c FROM Contract__c WHERE RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Account__c = :accountId',
        'JobPosting__c' => 'SELECT Id, Status__c FROM JobPosting__c WHERE Status__c = \'ACTIVE\' AND Account__c = :accountId',
        'IACooperation__c' => 'SELECT Id, Status__c, IACase__c FROM IACooperation__c WHERE Status__c = \'AKTIV\' AND Account__c = :accountId AND (IACase__r.CaseStatus__c IN (\'NY\', \'VURDERES\', \'KONTAKTES\', \'KARTLEGGES\', \'VI_BISTÅR\'))',
        'Workfare__c' => 'SELECT Id, Status__c FROM Workfare__c WHERE Status__c = \'GJENNOMFØRES\' AND Account__c = :accountId'
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

    // Centralized badge config
    private static final Map<String, Map<String, String>> BADGE_CONFIG = new Map<String, Map<String, String>>{
        'Muligheter' => new Map<String, String>{
            'labelTemplate' => 'Muligheter({0})',
            'helpText' => 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".',
            'reportName' => 'Muligheter_4WR',
            'badgeType' => 'Muligheter'
        },
        'Stillinger' => new Map<String, String>{
            'labelTemplate' => 'Stillinger({0})',
            'helpText' => 'Antall aktive offentlige utlyste- og direktemeldte stillinger.',
            'reportName' => 'Stillinger_adu',
            'badgeType' => 'Stillinger'
        },
        'Tiltak' => new Map<String, String>{
            'labelTemplate' => 'Tiltak({0})',
            'helpText' => 'Antall aktive tiltak registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.',
            'reportName' => 'Aktive_tiltak_tilknyttet_arbeidsgiver',
            'badgeType' => 'Tiltak'
        }
        // Add more badge configs as needed
    };

    // Helper to create a badge from config
    private static Badge createBadgeFromConfig(String key, Integer count, String extraFilters) {
        Map<String, String> config = BADGE_CONFIG.get(key);
        if (config == null) return null;
        String label = String.format(config.get('labelTemplate'), new List<Object>{ count });
        String url = getReportUrl(config.get('reportName'), extraFilters);
        return new Badge(label, config.get('helpText'), url, config.get('badgeType'));
    }

    // Static methods to create specific badges

    // Creates badge for Muligheter. Counts open opportunities.
    // Links to report Muligheter_4WR with filter order: AccountId (fv0), InquiryCategory__c(fv1)
    private static List<Badge> createOpportunityCountBadge(List<CustomOpportunity__c> activeOpportunities) {
        List<Badge> badges = new List<Badge>();
        if (activeOpportunities.size() >= 1) {
            Badge badge = createBadgeFromConfig('Muligheter', activeOpportunities.size(), '&fv2=');
            if (badge != null) badges.add(badge);
        }
        return badges;
    }

    // Creates badge for Avtaler. Display badge for each region-category combo.
    // Links to report Avtaler_Zsu with filter order: AccountId (fv0), Recordtype(fv1), TAG_Category__c(fv2), Region__c(fv3), TAG_Type_Partner__c(fv4)
    private static List<Badge> createAgreementBadges(List<Contract__c> employerAgreements) {
        String labelTemplate = '{0} {1}';
        String helpText = 'Bedriften har aktiv samarbeidsavtale innen angitt region og kategori.';
        Map<String, Badge> badges = new Map<String, Badge>();
        for (Contract__c employerAgreement : employerAgreements) {
            if (!String.isBlank(employerAgreement.Region__c) && !String.isBlank(employerAgreement.TAG_Category__c)) {
                String category = employerAgreement.TAG_Category__c.replaceAll('\\(.*\\)', '').trim();
                category = category.startsWith('IA') ? category : category.toLowerCase();
                String label = String.format(labelTemplate, new List<Object>{ employerAgreement.Region__c, category });
                String url = getReportUrl(
                    'Avtaler_Zsu',
                    '&fv2=' + employerAgreement.TAG_Category__c + '&fv3=' + employerAgreement.Region__c + '&fv4='
                );
                String badgeType = 'Samarbeidsavtale';
                Badge badge = new Badge(label, helpText, url, badgeType);
                badges.put(label, badge);
            }
        }
        return badges.values();
    }

    // Creates badge for partner status. Display badge for each partner type.
    /* TAG_Category__c
     * IA-samarbeid - enten avtale eller samarbeid
     * Strategisk partner - har strategisk partneravtale
     * Marked-samarbeid - har avtale med tilsvarende kategori
     */
    // Links to report Avtaler_Zsu with filter order: AccountId (fv0), Recordtype(fv1), TAG_Category__c(fv2), Region__c(fv3), TAG_Type_Partner__c(fv4)
    private static List<Badge> createPartnerTypeBadge(
        List<Contract__c> employerAgreements,
        List<IACooperation__c> iaCooperations
    ) {
        String helpText = 'Denne bedriftens partnerstatus basert på aktive avtaler og IA-samarbeid.';
        Map<String, Badge> badges = new Map<String, Badge>();

        Set<String> partnerStatuses = new Set<String>();
        for (Contract__c con : employerAgreements) {
            if (!String.isBlank(con.TAG_Category__c)) {
                partnerStatuses.add(con.TAG_Category__c);
            }
        }

        // Check if there are any IA cooperations and add IA cooperation badge if so
        if (iaCooperations.size() >= 1) {
            String label = 'IA-samarbeid';
            // Links to IA Case lightning page
            String url = '/lightning/r/IACase__c/' + iaCooperations[0].IACase__c + '/view';
            String badgeType = 'IA-samarbeid';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        // Create badges for Contracts
        for (String value : partnerStatuses) {
            if (value == 'IA-samarbeid' && !badges.containsKey('IA-samarbeid')) {
                String label = 'IA-samarbeid';
                String url = getReportUrl('Avtaler_Zsu', '&fv2=' + value);
                String badgeType = 'IA-samarbeid';
                Badge badge = new Badge(label, helpText, url, badgeType);
                badges.put(label, badge);
            } else if (value == 'Strategisk partner' && !badges.containsKey('Strategisk partner')) {
                String label = 'Strategisk partner';
                String url = getReportUrl('Avtaler_Zsu', '&fv2=' + value);
                String badgeType = 'Strategisk partner';
                Badge badge = new Badge(label, helpText, url, badgeType);
                badges.put(label, badge);
            } else if (value == 'Marked-samarbeid' && !badges.containsKey('Marked-samarbeid')) {
                String label = 'Marked-samarbeid';
                String url = getReportUrl('Avtaler_Zsu', '&fv2=' + value);
                String badgeType = 'Marked-samarbeid';
                Badge badge = new Badge(label, helpText, url, badgeType);
                badges.put(label, badge);
            }
        }
        return badges.values();
    }

    // Creates badge for job postings at employer.
    // Links to report Stillinger_adu with filter order: AccountId (fv0)
    private static List<Badge> createJobPostingBadge(List<JobPosting__c> jobPostings) {
        List<Badge> badges = new List<Badge>();
        if (jobPostings.size() >= 1) {
            Badge badge = createBadgeFromConfig('Stillinger', jobPostings.size(), '&fv2=');
            if (badge != null) badges.add(badge);
        }
        return badges;
    }

    // Creates badge for workfare at employer.
    // Links to report Tiltak_adu with filter order: AccountId (fv0)
    private static List<Badge> createWorkfareBadge(List<Workfare__c> workfares) {
        List<Badge> badges = new List<Badge>();
        if (workfares.size() >= 1) {
            Badge badge = createBadgeFromConfig('Tiltak', workfares.size(), '&fv2=');
            if (badge != null) badges.add(badge);
        }
        return badges;
    }

    // Helper methods
    // Returns report URL with filters
    private static string getReportUrl(String reportDeveloperName, String filters) {
        String reportId = getReportId(reportDeveloperName);
        if (String.isEmpty(reportId)) {
            return null; // report not found
        }
        return '/lightning/r/Report/' + reportId + '/view?fv0=' + recordId + filters;
    }
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
