/**
 * @description Controller class for managing badges on account page.
 */
public with sharing class AccountBadgesController {
    private static Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    private static final LoggerUtility LOGGER = new LoggerUtility();
    private static Id recordId;
    private static Map<String, String> reportIdMap;

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
            /*Account account = fetchAccount(accountId);
            if (account == null) {
                return new List<Badge>();
            }*/
            List<Contract__c> employerAgreements = fetchEmployerAgreements(accountId);
            List<CustomOpportunity__c> employerOpportunities = fetchOpportunities(accountId);
            List<JobPosting__c> employerJobPostings = fetchJobPostings(accountId);
            List<IACooperation__c> employerIACooperations = fetchIACooperations(accountId);
            List<Workfare__c> employerWorkfares = fetchWorkfares(accountId);
            addContractBadges(accountBadges, employerAgreements);
            //addAccountBadges(accountBadges, account);
            addOpportunityBadges(accountBadges, employerOpportunities);
            addJobPostingBadges(accountBadges, employerJobPostings);
            addIACooperationBadges(accountBadges, employerIACooperations);
            addWorkfareBadges(accountBadges, employerWorkfares);
        } catch (Exception e) {
            logError(accountId, e);
            return new List<Badge>();
        }
        return accountBadges;
    }

    /**
     * @description Fetches an Account record.
     * @param accountId The Id of the Account to fetch.
     * @return The Account record.
     */
    private static Account fetchAccount(Id accountId) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            return null;
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.Account.fields.NumberOfWorkfare__c.isAccessible()) {
            query += ',NumberOfWorkfare__c';
        }
        query += ' FROM Account WHERE Id = :accountId AND IsPersonAccount = FALSE';
        List<Account> accounts = Database.query(query);
        if (accounts.isEmpty()) {
            return null;
        } else {
            return accounts[0];
        }
    }
    /**
     * @description Fetches CustomOpportunity__c records.
     * @param accountId The Id of the Account to fetch opportunities for.
     * @return List of CustomOpportunity__c records.
     */
    private static List<CustomOpportunity__c> fetchOpportunities(Id accountId) {
        if (!Schema.sObjectType.CustomOpportunity__c.isAccessible()) {
            return new List<CustomOpportunity__c>();
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.CustomOpportunity__c.fields.InquiryCategory__c.isAccessible()) {
            query += ',InquiryCategory__c';
        }
        if (Schema.sObjectType.CustomOpportunity__c.fields.InclusionStage__c.isAccessible()) {
            query += ',InclusionStage__c';
        }
        query += ' FROM CustomOpportunity__c WHERE InclusionStage__c != \'Avsluttet\' AND Account__c = :accountId';
        List<CustomOpportunity__c> opportunities = Database.query(query);
        return opportunities;
    }

    /**
     * @description Fetches Contract records.
     * @param accountId The Id of the Account to fetch contracts for.
     * @return List of Contract__c records.
     */
    private static List<Contract__c> fetchEmployerAgreements(Id accountId) {
        if (!Schema.sObjectType.Contract__c.isAccessible()) {
            return new List<Contract__c>();
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.Contract__c.fields.Region__c.isAccessible()) {
            query += ',Region__c';
        }
        if (Schema.sObjectType.Contract__c.fields.TAG_Category__c.isAccessible()) {
            query += ',TAG_Category__c';
        }
        if (Schema.sObjectType.Contract__c.fields.TAG_Type_Partner__c.isAccessible()) {
            query += ',TAG_Type_Partner__c';
        }
        query += ' FROM Contract__c WHERE';
        query += ' RecordType.DeveloperName = \'EmployerAgreement\'';
        query += ' AND TAG_Status__c = \'Godkjent\'';
        query += ' AND TAG_EndDate__c > TODAY';
        query += ' AND TAG_StartDate__c <= TODAY';
        query += ' AND TAG_Account__c = :accountId';

        List<Contract__c> contracts = Database.query(query);
        return contracts;
    }

    /**
     * @description Fetches JobPosting__c records.
     * @param accountId The Id of the Account to fetch jobpostings for.
     * @return List of JobPosting__c records.
     */
    private static List<JobPosting__c> fetchJobPostings(Id accountId) {
        if (!Schema.sObjectType.JobPosting__c.isAccessible()) {
            return new List<JobPosting__c>();
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.JobPosting__c.fields.Status__c.isAccessible()) {
            query += ',Status__c';
        }
        query += ' FROM JobPosting__c WHERE Status__c = \'ACTIVE\' AND Account__c = :accountId';
        List<JobPosting__c> jobPostings = Database.query(query);
        return jobPostings;
    }

    /**
     * @description Fetches IACooperation__c records.
     * @param accountId The Id of the Account to fetch IA cooperations for.
     * @return List of IACooperation__c records.
     */
    private static List<IACooperation__c> fetchIACooperations(Id accountId) {
        if (!Schema.sObjectType.IACooperation__c.isAccessible()) {
            return new List<IACooperation__c>();
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.IACooperation__c.fields.Status__c.isAccessible()) {
            query += ',Status__c';
        }
        if (Schema.sObjectType.IACooperation__c.fields.IACase__c.isAccessible()) {
            query += ',IACase__c';
        }
        // Temporary filter on IA Case since implementation of cooperation status is incomplete
        String activeIaCaseFilter = '(IACase__r.CaseStatus__c =\'NY\' OR IACase__r.CaseStatus__c =\'VURDERES\' OR IACase__r.CaseStatus__c =\'KONTAKTES\' OR IACase__r.CaseStatus__c =\'KARTLEGGES\' OR IACase__r.CaseStatus__c =\'VI_BISTÅR\')';
        query +=
            ' FROM IACooperation__c WHERE Status__c = \'AKTIV\' AND ' +
            activeIaCaseFilter +
            ' AND Account__c = :accountId';
        List<IACooperation__c> iaCooperations = Database.query(query);
        return iaCooperations;
    }

    /**
     * @description Fetches Workfare__c records.
     * @param accountId The Id of the Account to fetch workfares for.
     * @return List of Workfare__c records.
     */
    private static List<Workfare__c> fetchWorkfares(Id accountId) {
        if (!Schema.sObjectType.Workfare__c.isAccessible()) {
            return new List<Workfare__c>();
        }
        String query = 'SELECT Id';
        if (Schema.sObjectType.Workfare__c.fields.Status__c.isAccessible()) {
            query += ',Status__c';
        }
        query += ' FROM Workfare__c WHERE Status__c = \'GJENNOMFØRES\' AND Account__c = :accountId';
        List<Workfare__c> workfares = Database.query(query);
        return workfares;
    }

    /**
     * @description Adds badges to the accountBadges list based on the Account fields.
     * @param accountBadges The list of badges to add to.
     * @param account The Account record to evaluate.
     */
    private static void addAccountBadges(List<Badge> accountBadges, Account account) {
        accountBadges.addAll(createNumberOfWorkfareBadge(account));
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
        accountBadges.addAll(createOpportunityCountBadge(activeOpportunities));
    }

    /**
     * @description Adds badges to the accountBadges list based on the related Contract__c records.
     * @param accountBadges The list of badges to add to.
     * @param employerAgreements The related Contract__c records to evaluate.
     */
    private static void addContractBadges(List<Badge> accountBadges, List<Contract__c> employerAgreements) {
        accountBadges.addAll(createAgreementBadges(employerAgreements));
        accountBadges.addAll(createPartnerTypeBadge(employerAgreements));
    }

    /**
     * @description Adds badges to the accountBadges list based on the related JobPosting__c records.
     * @param accountBadges The list of badges to add to.
     * @param jobPostings The related JobPosting__c records to evaluate.
     */
    private static void addJobPostingBadges(List<Badge> accountBadges, List<JobPosting__c> jobPostings) {
        accountBadges.addAll(createJobPostingBadge(jobPostings));
    }

    /**
     * @description Adds badges to the accountBadges list based on the related IACooperation__c records.
     * @param accountBadges The list of badges to add to.
     * @param iaCooperations The related IACooperation__c records to evaluate.
     */
    private static void addIACooperationBadges(List<Badge> accountBadges, List<IACooperation__c> iaCooperations) {
        accountBadges.addAll(createIACooperationBadge(iaCooperations));
    }

    /**
     * @description Adds badges to the accountBadges list based on the related Workfare__c records.
     * @param accountBadges The list of badges to add to.
     * @param workfares The related Workfare__c records to evaluate.
     */
    private static void addWorkfareBadges(List<Badge> accountBadges, List<Workfare__c> workfares) {
        accountBadges.addAll(createWorkfareBadge(workfares));
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

    // Static methods to create specific badges
    // Creates badge for Aktive tiltak.
    private static List<Badge> createNumberOfWorkfareBadge(Account account) {
        String labelTemplate = 'Aktive tiltak({0})';
        String helpText = accountFields.get('NumberOfWorkfare__c').getDescribe().getInlineHelpText();
        Map<String, Badge> badges = new Map<String, Badge>();
        if (account.NumberOfWorkfare__c >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ account.NumberOfWorkfare__c });
            String url = getReportUrl('Aktive_Tiltaksavtaler_per_Virksomhet', '');
            String badgeType = 'Tiltak';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        return badges.values();
    }

    // Creates badge for Muligheter. Counts open opportunities.
    // Links to report Muligheter_4WR with filter order: AccountId (fv0), InquiryCategory__c(fv1)
    private static List<Badge> createOpportunityCountBadge(List<CustomOpportunity__c> activeOpportunities) {
        String labelTemplate = 'Muligheter({0})';
        String helpText = 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".';
        Map<String, Badge> badges = new Map<String, Badge>();
        if (activeOpportunities.size() >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ activeOpportunities.size() });
            String url = getReportUrl('Muligheter_4WR', '&fv2=');
            String badgeType = 'Muligheter';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        return badges.values();
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
    // Links to report Avtaler_Zsu with filter order: AccountId (fv0), Recordtype(fv1), TAG_Category__c(fv2), Region__c(fv3), TAG_Type_Partner__c(fv4)
    private static List<Badge> createPartnerTypeBadge(List<Contract__c> employerAgreements) {
        String labelTemplate = '{0}';
        String helpText = 'Denne bedriftens partnerstatus basert på aktive avtaler.';
        Map<String, Badge> badges = new Map<String, Badge>();
        for (Contract__c employerAgreement : employerAgreements) {
            if (!String.isBlank(employerAgreement.TAG_Type_Partner__c)) {
                String label = String.format(labelTemplate, new List<Object>{ employerAgreement.TAG_Type_Partner__c });
                label = label.toLowerCase().capitalize();
                String url = getReportUrl(
                    'Avtaler_Zsu',
                    '&fv2=' + '&fv3=' + '&fv4=' + employerAgreement.TAG_Type_Partner__c
                );
                String badgeType = 'Partnerstatus';
                Badge badge = new Badge(label, helpText, url, badgeType);
                badges.put(label, badge);
            }
        }
        return badges.values();
    }

    // Creates badge for job postings at employer.
    // Links to report Stillinger_adu with filter order: AccountId (fv0)
    private static List<Badge> createJobPostingBadge(List<JobPosting__c> jobPostings) {
        String labelTemplate = 'Stillinger({0})';
        String helpText = 'Antall aktive offentlige utlyste- og direktemeldte stillinger.';
        Map<String, Badge> badges = new Map<String, Badge>();
        if (jobPostings.size() >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ jobPostings.size() });
            String url = getReportUrl('Stillinger_adu', '&fv2=');
            String badgeType = 'Stillinger';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        return badges.values();
    }

    // Creates badge for IA cooperations at employer.
    // Links to IA Case lightning page
    private static List<Badge> createIACooperationBadge(List<IACooperation__c> iaCooperations) {
        String labelTemplate = 'IA-samarbeid({0})';
        String helpText = 'Antall aktive IA-samarbeid for denne bedriften.';
        Map<String, Badge> badges = new Map<String, Badge>();
        if (iaCooperations.size() >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ iaCooperations.size() });
            String url = '/lightning/r/IACase__c/' + iaCooperations[0].IACase__c + '/view';
            String badgeType = 'IA-samarbeid';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        return badges.values();
    }

    // Creates badge for workfare at employer.
    // Links to report Tiltak_adu with filter order: AccountId (fv0)
    private static List<Badge> createWorkfareBadge(List<Workfare__c> workfares) {
        String labelTemplate = 'Tiltak({0})';
        String helpText = 'Antall aktive tiltak registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.';
        Map<String, Badge> badges = new Map<String, Badge>();
        if (workfares.size() >= 1) {
            String label = String.format(labelTemplate, new List<Object>{ workfares.size() });
            String url = getReportUrl('Aktive_tiltak_tilknyttet_arbeidsgiver', '&fv2=');
            String badgeType = 'Tiltak';
            Badge badge = new Badge(label, helpText, url, badgeType);
            badges.put(label, badge);
        }
        return badges.values();
    }

    private static string getReportUrl(String reportDeveloperName, String filters) {
        String reportId = getReportId(reportDeveloperName);
        if (String.isEmpty(reportId)) {
            return null; // report not found
        }
        return '/lightning/r/Report/' + reportId + '/view?fv0=' + recordId + filters;
    }

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
