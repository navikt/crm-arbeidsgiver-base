/**
 * Calculates candidate and meeting metrics for contract batch scopes.
 */
public with sharing class TAG_ContractMetricsService {
    private static final String STATUS_APPROVED = 'Godkjent';
    private static final String STATUS_CLOSED = 'AVSLUTTET';
    private static final String RESULT_PRESENTED = 'PRESENTERT';
    private static final String RESULT_HIRED = 'FATT_JOBBEN';
    private static final String RECRUITMENT_ACTIVITY_TYPE = 'Rekruttere og inkludere';
    private static final String EXCLUDED_SERVICE = 'IPS Jobbutvikling';
    private static final LoggerUtility LOGGER = new LoggerUtility();

    /**
     * Calculates changed metric values and persists them, logging any DML failure.
     * @param contracts Contracts from one batch scope.
     */
    public static void applyChanges(List<Contract__c> contracts) {
        MetricScope scope = createMetricScope(contracts);
        if (scope == null || scope.eligibleContracts.isEmpty()) {
            return;
        }
        MetricSourceData sourceData = loadMetricData(scope);
        List<Contract__c> changedContracts = createChangedContracts(scope, sourceData);

        if (changedContracts.isEmpty()) {
            return;
        }
        List<Database.SaveResult> results = Database.update(changedContracts, false, AccessLevel.USER_MODE);
        String firstErrorMessage;
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                String errorMessage = result.getErrors()[0].getMessage();
                logError(result.getId(), errorMessage);
                firstErrorMessage = firstErrorMessage == null ? errorMessage : firstErrorMessage;
            }
        }
        if (firstErrorMessage != null) {
            throw new ContractMetricsException(firstErrorMessage);
        }
    }

    /**
     * Creates a metric scope containing only eligible contracts and relevant date ranges.
     * @param contracts Contracts from one batch scope.
     * @return A MetricScope object containing only eligible contracts and relevant date ranges.
     */
    private static MetricScope createMetricScope(List<Contract__c> contracts) {
        MetricScope scope = new MetricScope();
        if (contracts == null || contracts.isEmpty()) {
            return null;
        }
        scope.earliestStartDate = contracts[0].TAG_StartDate__c;
        scope.latestEndDate = contracts[0].TAG_EndDate__c;
        for (Contract__c contractRecord : contracts) {
            if (isEligibleContract(contractRecord)) {
                scope.eligibleContracts.add(contractRecord);
                scope.accountIds.add(contractRecord.TAG_Account__c);

                scope.earliestStartDate = contractRecord.TAG_StartDate__c < scope.earliestStartDate
                    ? contractRecord.TAG_StartDate__c
                    : scope.earliestStartDate;

                scope.latestEndDate = contractRecord.TAG_EndDate__c > scope.latestEndDate
                    ? contractRecord.TAG_EndDate__c
                    : scope.latestEndDate;
            }
        }
        return scope;
    }

    /**
     * Loads metric data for the given scope. Retrieves all relevant records for the contracts in scope. Records are grouped by contract and stored as a MetricSourceData wrapper object.
     * @param scope The MetricScope object containing eligible contracts and relevant date ranges.
     * @return A MetricSourceData object containing the loaded metric data.
     */
    private static MetricSourceData loadMetricData(MetricScope scope) {
        MetricSourceData sourceData = new MetricSourceData();
        Datetime earliestStartTimestamp = Datetime.newInstance(scope.earliestStartDate, Time.newInstance(0, 0, 0, 0));
        Datetime latestEndDateTimestamp = Datetime.newInstance(
            scope.latestEndDate.addDays(1),
            Time.newInstance(0, 0, 0, 0)
        );

        // presentedOutcomes grouped by account. PRESENTERT stores the related account in Account2__c, FATT_JOBBEN stores it in Account__c.
        for (CandidateOutcome__c outcome : [
            SELECT Account2__c, TimeRegistered__c
            FROM CandidateOutcome__c
            WHERE
                Account2__c IN :scope.accountIds
                AND Result__c = :RESULT_PRESENTED
                AND TimeRegistered__c >= :earliestStartTimestamp
                AND TimeRegistered__c < :latestEndDateTimestamp
            WITH USER_MODE
        ]) {
            sourceData.updatePresentedOutcomesByAccount(
                outcome.Account2__c,
                new MetricSourceDataObj(outcome.TimeRegistered__c, outcome.Account2__c)
            );
        }

        // hiredOutcomes
        for (CandidateOutcome__c outcome : [
            SELECT Account__c, TimeRegistered__c
            FROM CandidateOutcome__c
            WHERE
                Account__c IN :scope.accountIds
                AND Result__c = :RESULT_HIRED
                AND TimeRegistered__c >= :earliestStartTimestamp
                AND TimeRegistered__c < :latestEndDateTimestamp
            WITH USER_MODE
        ]) {
            sourceData.updateHiredOutcomesByAccount(
                outcome.Account__c,
                new MetricSourceDataObj(outcome.TimeRegistered__c, outcome.Account__c)
            );
        }

        // meetingsByAccount
        for (Event meeting : [
            SELECT RelatedToAccount__c, ActivityDate
            FROM Event
            WHERE
                RelatedToAccount__c IN :scope.accountIds
                AND ActivityDate >= :scope.earliestStartDate
                AND ActivityDate <= :scope.latestEndDate
                AND TAG_ActivityType__c = :RECRUITMENT_ACTIVITY_TYPE
                AND (TAG_service__c = NULL
                OR TAG_service__c != :EXCLUDED_SERVICE)
            WITH USER_MODE
        ]) {
            sourceData.updateMeetingsByAccount(
                meeting.RelatedToAccount__c,
                new MetricSourceDataObj(meeting.ActivityDate, meeting.RelatedToAccount__c)
            );
        }
        return sourceData;
    }

    /**
     * Iterates over eligible contracts and calculates changes based on metric data.
     * @param scope The MetricScope object containing eligible contracts and relevant date ranges.
     * @param sourceData The MetricSourceData object containing the loaded metric data.
     * @return A list of Contract__c records that have changes in their metrics.
     */
    private static List<Contract__c> createChangedContracts(MetricScope scope, MetricSourceData sourceData) {
        List<Contract__c> changedContracts = new List<Contract__c>();
        for (Contract__c contract : scope.eligibleContracts) {
            Id accountId = contract.TAG_Account__c;
            Integer presentedCandidatesCount;
            Integer hiredCandidatesCount;
            Integer meetingsCount;
            presentedCandidatesCount = getObjCountInDateRange(
                sourceData.presentedOutcomesByAccount.get(accountId),
                contract.TAG_StartDate__c,
                contract.TAG_EndDate__c
            );

            hiredCandidatesCount = getObjCountInDateRange(
                sourceData.hiredOutcomesByAccount.get(accountId),
                contract.TAG_StartDate__c,
                contract.TAG_EndDate__c
            );
            meetingsCount = getObjCountInDateRange(
                sourceData.meetingsByAccount.get(accountId),
                contract.TAG_StartDate__c,
                contract.TAG_EndDate__c
            );
            if (
                contract.TAG_NumberOfHiredCandidates__c != hiredCandidatesCount ||
                contract.TAG_NumberOfPresentedCandidates__c != presentedCandidatesCount ||
                contract.TAG_NumberOfMeetings__c != meetingsCount
            ) {
                changedContracts.add(
                    new Contract__c(
                        Id = contract.Id,
                        TAG_NumberOfHiredCandidates__c = hiredCandidatesCount,
                        TAG_NumberOfPresentedCandidates__c = presentedCandidatesCount,
                        TAG_NumberOfMeetings__c = meetingsCount
                    )
                );
            }
        }
        return changedContracts;
    }

    private static Integer getObjCountInDateRange(List<MetricSourceDataObj> objs, Date startDate, Date endDate) {
        Integer count = 0;
        if (objs == null) {
            return 0;
        }
        for (MetricSourceDataObj obj : objs) {
            if (obj.recordDate >= startDate && obj.recordDate <= endDate) {
                count++;
            }
        }
        return count;
    }
    /**
     * Checks if a contract has all required fields and an approved or closed status.
     * @param contractRecord The contract record to check for eligibility.
     * @return True if the contract has all required fields and an approved or closed status, false otherwise.
     */
    private static boolean isEligibleContract(Contract__c contractRecord) {
        return contractRecord.TAG_Account__c != null &&
            contractRecord.TAG_StartDate__c != null &&
            contractRecord.TAG_EndDate__c != null &&
            contractRecord.TAG_StartDate__c <= contractRecord.TAG_EndDate__c &&
            (contractRecord.TAG_Status__c == STATUS_APPROVED ||
            contractRecord.TAG_Status__c == STATUS_CLOSED);
    }

    /**
     * Logs an error message for a specific record.
     * @param recordId The ID of the record for which the error occurred.
     * @param message The error message to log.
     */
    private static void logError(Id recordId, String message) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            recordId,
            message,
            null,
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        LOGGER.publish();
    }

    /**
     * Represents the scope of metrics for a set of contracts.
     * Contains eligible contracts, associated account IDs, and date ranges.
     */
    private class MetricScope {
        private List<Contract__c> eligibleContracts = new List<Contract__c>();
        private Set<Id> accountIds = new Set<Id>();
        private Date earliestStartDate;
        private Date latestEndDate;
    }

    /**
     * Represents the source data for metrics calculation.
     * Contains presented and hired candidate outcomes, as well as meetings, grouped by account ID.
   
    private class MetricSourceData {
        private Map<Id, List<CandidateOutcome__c>> presentedOutcomesByAccount = new Map<Id, List<CandidateOutcome__c>>();
        private Map<Id, List<CandidateOutcome__c>> hiredOutcomesByAccount = new Map<Id, List<CandidateOutcome__c>>();
        private Map<Id, List<Event>> meetingsByAccount = new Map<Id, List<Event>>();
    }
          */

    private class MetricSourceData {
        private Map<Id, List<MetricSourceDataObj>> presentedOutcomesByAccount = new Map<Id, List<MetricSourceDataObj>>();
        private Map<Id, List<MetricSourceDataObj>> hiredOutcomesByAccount = new Map<Id, List<MetricSourceDataObj>>();
        private Map<Id, List<MetricSourceDataObj>> meetingsByAccount = new Map<Id, List<MetricSourceDataObj>>();

        private void updatePresentedOutcomesByAccount(Id accountId, MetricSourceDataObj value) {
            addToAccountMap(accountId, presentedOutcomesByAccount, value);
        }
        private void updateHiredOutcomesByAccount(Id accountId, MetricSourceDataObj value) {
            addToAccountMap(accountId, hiredOutcomesByAccount, value);
        }
        private void updateMeetingsByAccount(Id accountId, MetricSourceDataObj value) {
            addToAccountMap(accountId, meetingsByAccount, value);
        }
        private void addToAccountMap(
            Id key,
            Map<Id, List<MetricSourceDataObj>> mapByAccount,
            MetricSourceDataObj value
        ) {
            if (!mapByAccount.containsKey(key)) {
                mapByAccount.put(key, new List<MetricSourceDataObj>());
            }
            mapByAccount.get(key).add(value);
        }
    }

    private class MetricSourceDataObj {
        Date recordDate;
        Id recordId;
        Id accountId;
        MetricSourceDataObj(Datetime recordTimestamp, Id accountId) {
            this.recordDate = recordTimestamp.date();
            this.accountId = accountId;
        }
        MetricSourceDataObj(Date recordDate, Id accountId) {
            this.recordDate = recordDate;
            this.accountId = accountId;
        }
    }

    public class ContractMetricsException extends Exception {
    }
}
