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

    private static void populateCandidateStats(Id navUnitId, NavUnitOverviewData data) {
        AggregateResult[] groupedResults = [
            SELECT COUNT(Id), Result__c
            FROM CandidateOutcome__c
            WHERE
                NavUnit__c = :navUnitId
                AND Result__c IN ('PRESENTERT', 'FATT_JOBBEN')
                AND TimeRegistered__c = LAST_N_DAYS:90
            WITH USER_MODE
            GROUP BY Result__c
        ];

        data.candidatesPresentedCount = 0;
        data.candidatesPlacedCount = 0;
        for (AggregateResult ar : groupedResults) {
            if ((String) ar.get('Result__c') == 'PRESENTERT') {
                data.candidatesPresentedCount = (Integer) ar.get('expr0');
            } else if ((String) ar.get('Result__c') == 'FATT_JOBBEN') {
                data.candidatesPlacedCount = (Integer) ar.get('expr0');
            }
        }
    }

    private static void populateEmployerActivityStats(Id navUnitId, NavUnitOverviewData data) {
        data.employersWithActivityCount = [
            SELECT COUNT()
            FROM Account
            WHERE
                RecordType.Name = 'Employer'
                AND TAG_NavUnit__c = :navUnitId
                AND TAG_Last_completed_activity_date__c = LAST_N_DAYS:90
            WITH USER_MODE
        ];

        AggregateResult[] lastActivity = [
            SELECT MAX(TAG_Last_completed_activity_date__c) lastDate
            FROM Account
            WHERE RecordType.Name = 'Employer' AND TAG_NavUnit__c = :navUnitId
            WITH USER_MODE
        ];
        Date lastActivityDate = (Date) lastActivity[0].get('lastDate');
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
