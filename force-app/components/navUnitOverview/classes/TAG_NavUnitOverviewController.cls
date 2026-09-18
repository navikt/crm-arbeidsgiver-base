/**
 * Provides activity and outcome metrics for a Nav unit.
 * Responsible for data retrival and aggregation for the overview metrics.
 */
public with sharing class TAG_NavUnitOverviewController {
    /**
     * Contains the metrics displayed in the NAV unit overview.
     */
    public class NavUnitOverviewData {
        @AuraEnabled
        public Integer inquiriesClosedCount;
        @AuraEnabled
        public Integer inquiriesClosedWithinDeadlineCount;
        @AuraEnabled
        public Integer candidatesPresentedCount;
        @AuraEnabled
        public Integer candidatesPlacedCount;
        @AuraEnabled
        public Integer employersWithActivityCount;
        @AuraEnabled
        public Integer daysSinceLastActivity;
        @AuraEnabled
        public Datetime dataRetrivalTimestamp;
    }

    /**
     * Retrieves overview metrics for the supplied Nav unit.
     *
     * @param navUnitId The identifier of the Nav unit.
     * @return The calculated overview metrics.
     * @throws AuraHandledException When the Nav unit identifier is missing or the user lacks read access.
     */
    @AuraEnabled(cacheable=true)
    public static NavUnitOverviewData getOverview(Id navUnitId) {
        if (navUnitId == null) {
            throw new AuraHandledException('navUnitId er påkrevd');
        }
        checkReadAccess();

        NavUnitOverviewData data = new NavUnitOverviewData();
        populateInquiryStats(navUnitId, data);
        populateCandidateStats(navUnitId, data);
        populateEmployerActivityStats(navUnitId, data);
        setDataRetrivalTimestamp(data);
        return data;
    }

    private static void setDataRetrivalTimestamp(NavUnitOverviewData data) {
        data.dataRetrivalTimestamp = Datetime.now();
    }

    private static void populateInquiryStats(Id navUnitId, NavUnitOverviewData data) {
        AggregateResult[] groupedResults = [
            SELECT COUNT(Id), TAG_ClosedAfterDueDate__c
            FROM EmployerInquiry__c
            WHERE
                TAG_NavUnit__c = :navUnitId
                AND TAG_RecievedDateTime__c = LAST_N_DAYS:90
                AND TAG_Status__c = 'Fullført'
                AND TAG_IsConversationNote__c = FALSE
            WITH USER_MODE
            GROUP BY TAG_ClosedAfterDueDate__c
        ];
        data.inquiriesClosedCount = 0;
        data.inquiriesClosedWithinDeadlineCount = 0;
        for (AggregateResult ar : groupedResults) {
            if ((Boolean) ar.get('TAG_ClosedAfterDueDate__c') == false) {
                data.inquiriesClosedWithinDeadlineCount += (Integer) ar.get('expr0');
            }
            data.inquiriesClosedCount += (Integer) ar.get('expr0');
        }
    }

    /*
    Bruker sum ansatte / sum presenterte.
    Dette er samlet konverteringsrate: sannsynligheten for at en tilfeldig kandidatrepresentasjon ender i ansettelse.
    */
    private static void populateCandidateStats(Id navUnitId, NavUnitOverviewData data) {
        AggregateResult[] groupedResults = [
            SELECT COUNT(Id), JobPosting__c, Result__c
            FROM CandidateOutcome__c
            WHERE
                NavUnit__c = :navUnitId
                AND Result__c IN ('PRESENTERT', 'FATT_JOBBEN')
                AND TimeRegistered__c = LAST_N_DAYS:90
                AND JobPosting__c != NULL
            WITH USER_MODE
            GROUP BY JobPosting__c, Result__c
        ];

        data.candidatesPresentedCount = 0;
        data.candidatesPlacedCount = 0;
        Map<Id, Map<String, Integer>> jobPostingResults = new Map<Id, Map<String, Integer>>();
        for (AggregateResult ar : groupedResults) {
            Id jobPostingId = (Id) ar.get('JobPosting__c');

            String result = (String) ar.get('Result__c');
            Integer count = (Integer) ar.get('expr0');

            if (!jobPostingResults.containsKey(jobPostingId)) {
                jobPostingResults.put(jobPostingId, new Map<String, Integer>{ 'PRESENTERT' => 0, 'FATT_JOBBEN' => 0 });
            }
            jobPostingResults.get(jobPostingId).put(result, count);
        }

        for (Map<String, Integer> resultCounts : jobPostingResults.values()) {
            Integer presentedCount = resultCounts.get('PRESENTERT');
            if (presentedCount == 0) {
                continue;
            }
            data.candidatesPresentedCount += presentedCount;
            data.candidatesPlacedCount += resultCounts.get('FATT_JOBBEN');
        }
    }

    private static void populateEmployerActivityStats(Id navUnitId, NavUnitOverviewData data) {
        AggregateResult[] activityStats = [
            SELECT COUNT(Id) countAccounts, MAX(TAG_Last_completed_activity_date__c) lastActivityDate
            FROM Account
            WHERE
                RecordType.Name = 'Employer'
                AND TAG_NavUnit__c = :navUnitId
                AND TAG_Last_completed_activity_date__c = LAST_N_DAYS:90
            WITH USER_MODE
        ];

        data.employersWithActivityCount = (Integer) activityStats[0].get('countAccounts');
        Date lastActivityDate = (Date) activityStats[0].get('lastActivityDate');
        data.daysSinceLastActivity = lastActivityDate == null ? null : lastActivityDate.daysBetween(Date.today());
    }

    private static void checkReadAccess() {
        Boolean hasAccess =
            Schema.sObjectType.NavUnit__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.fields.TAG_NavUnit__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.fields.TAG_RecievedDateTime__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.fields.TAG_Status__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.fields.TAG_IsConversationNote__c.isAccessible() &&
            Schema.sObjectType.EmployerInquiry__c.fields.TAG_ClosedAfterDueDate__c.isAccessible() &&
            Schema.sObjectType.CandidateOutcome__c.isAccessible() &&
            Schema.sObjectType.CandidateOutcome__c.fields.NavUnit__c.isAccessible() &&
            Schema.sObjectType.CandidateOutcome__c.fields.Result__c.isAccessible() &&
            Schema.sObjectType.CandidateOutcome__c.fields.TimeRegistered__c.isAccessible() &&
            Schema.sObjectType.Account.isAccessible() &&
            Schema.sObjectType.Account.fields.TAG_NavUnit__c.isAccessible() &&
            Schema.sObjectType.Account.fields.TAG_Last_completed_activity_date__c.isAccessible();

        if (!hasAccess) {
            throw new AuraHandledException('Du har ikke tilgang til å se disse nøkkeltallene');
        }
    }
}
