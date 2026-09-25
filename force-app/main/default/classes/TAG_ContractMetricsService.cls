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
        List<Contract__c> changedContracts = calculateChanges(contracts);
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
     * Calculates changed metric values without persisting them.
     * @param contracts Contracts from one batch scope.
     * @return Sparse Contract__c records containing only changed metrics.
     */
    private static List<Contract__c> calculateChanges(List<Contract__c> contracts) {
        List<Contract__c> eligibleContracts = getEligibleContracts(contracts);
        if (eligibleContracts.isEmpty()) {
            return new List<Contract__c>();
        }

        Set<Id> accountIds = new Set<Id>();
        Date earliestStartDate;
        Date latestEndDate;
        for (Contract__c contractRecord : eligibleContracts) {
            accountIds.add(contractRecord.TAG_Account__c);
            earliestStartDate = earliestStartDate == null ||
                contractRecord.TAG_StartDate__c < earliestStartDate
                ? contractRecord.TAG_StartDate__c
                : earliestStartDate;
            latestEndDate = latestEndDate == null ||
                contractRecord.TAG_EndDate__c > latestEndDate
                ? contractRecord.TAG_EndDate__c
                : latestEndDate;
        }

        Datetime earliestStart = Datetime.newInstance(earliestStartDate, Time.newInstance(0, 0, 0, 0));
        Datetime exclusiveLatestEnd = Datetime.newInstance(latestEndDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        // PRESENTERT stores the related account in Account2__c, FATT_JOBBEN stores it in Account__c.
        Map<Id, List<CandidateOutcome__c>> presentedOutcomesByAccount = groupPresentedOutcomesByAccount(
            [
                SELECT Account2__c, TimeRegistered__c
                FROM CandidateOutcome__c
                WHERE
                    Account2__c IN :accountIds
                    AND Result__c = :RESULT_PRESENTED
                    AND TimeRegistered__c >= :earliestStart
                    AND TimeRegistered__c < :exclusiveLatestEnd
                WITH USER_MODE
            ]
        );
        Map<Id, List<CandidateOutcome__c>> hiredOutcomesByAccount = groupHiredOutcomesByAccount(
            [
                SELECT Account__c, TimeRegistered__c
                FROM CandidateOutcome__c
                WHERE
                    Account__c IN :accountIds
                    AND Result__c = :RESULT_HIRED
                    AND TimeRegistered__c >= :earliestStart
                    AND TimeRegistered__c < :exclusiveLatestEnd
                WITH USER_MODE
            ]
        );
        Map<Id, List<Event>> meetingsByAccount = groupMeetingsByAccount(
            [
                SELECT RelatedToAccount__c, ActivityDate
                FROM Event
                WHERE
                    RelatedToAccount__c IN :accountIds
                    AND ActivityDate >= :earliestStartDate
                    AND ActivityDate <= :latestEndDate
                    AND TAG_ActivityType__c = :RECRUITMENT_ACTIVITY_TYPE
                    AND (TAG_service__c = NULL
                    OR TAG_service__c != :EXCLUDED_SERVICE)
                WITH USER_MODE
            ]
        );

        List<Contract__c> changedContracts = new List<Contract__c>();
        for (Contract__c contractRecord : eligibleContracts) {
            ContractMetrics metrics = calculateMetrics(
                contractRecord,
                presentedOutcomesByAccount.get(contractRecord.TAG_Account__c),
                hiredOutcomesByAccount.get(contractRecord.TAG_Account__c),
                meetingsByAccount.get(contractRecord.TAG_Account__c)
            );
            if (
                contractRecord.TAG_NumberOfHiredCandidates__c != metrics.hiredCandidates ||
                contractRecord.TAG_NumberOfPresentedCandidates__c != metrics.presentedCandidates ||
                contractRecord.TAG_NumberOfMeetings__c != metrics.meetings
            ) {
                changedContracts.add(
                    new Contract__c(
                        Id = contractRecord.Id,
                        TAG_NumberOfHiredCandidates__c = metrics.hiredCandidates,
                        TAG_NumberOfPresentedCandidates__c = metrics.presentedCandidates,
                        TAG_NumberOfMeetings__c = metrics.meetings
                    )
                );
            }
        }
        return changedContracts;
    }

    private static List<Contract__c> getEligibleContracts(List<Contract__c> contracts) {
        List<Contract__c> eligibleContracts = new List<Contract__c>();
        if (contracts == null) {
            return eligibleContracts;
        }
        for (Contract__c contractRecord : contracts) {
            if (
                contractRecord.TAG_Account__c != null &&
                contractRecord.TAG_StartDate__c != null &&
                contractRecord.TAG_EndDate__c != null &&
                contractRecord.TAG_StartDate__c <= contractRecord.TAG_EndDate__c &&
                (contractRecord.TAG_Status__c == STATUS_APPROVED ||
                contractRecord.TAG_Status__c == STATUS_CLOSED)
            ) {
                eligibleContracts.add(contractRecord);
            }
        }
        return eligibleContracts;
    }

    private static Map<Id, List<CandidateOutcome__c>> groupPresentedOutcomesByAccount(
        List<CandidateOutcome__c> outcomes
    ) {
        Map<Id, List<CandidateOutcome__c>> outcomesByAccount = new Map<Id, List<CandidateOutcome__c>>();
        for (CandidateOutcome__c outcome : outcomes) {
            if (!outcomesByAccount.containsKey(outcome.Account2__c)) {
                outcomesByAccount.put(outcome.Account2__c, new List<CandidateOutcome__c>());
            }
            outcomesByAccount.get(outcome.Account2__c).add(outcome);
        }
        return outcomesByAccount;
    }

    private static Map<Id, List<CandidateOutcome__c>> groupHiredOutcomesByAccount(List<CandidateOutcome__c> outcomes) {
        Map<Id, List<CandidateOutcome__c>> outcomesByAccount = new Map<Id, List<CandidateOutcome__c>>();
        for (CandidateOutcome__c outcome : outcomes) {
            if (!outcomesByAccount.containsKey(outcome.Account__c)) {
                outcomesByAccount.put(outcome.Account__c, new List<CandidateOutcome__c>());
            }
            outcomesByAccount.get(outcome.Account__c).add(outcome);
        }
        return outcomesByAccount;
    }

    private static Map<Id, List<Event>> groupMeetingsByAccount(List<Event> meetings) {
        Map<Id, List<Event>> meetingsByAccount = new Map<Id, List<Event>>();
        for (Event meeting : meetings) {
            if (!meetingsByAccount.containsKey(meeting.RelatedToAccount__c)) {
                meetingsByAccount.put(meeting.RelatedToAccount__c, new List<Event>());
            }
            meetingsByAccount.get(meeting.RelatedToAccount__c).add(meeting);
        }
        return meetingsByAccount;
    }

    private static ContractMetrics calculateMetrics(
        Contract__c contractRecord,
        List<CandidateOutcome__c> presentedOutcomes,
        List<CandidateOutcome__c> hiredOutcomes,
        List<Event> meetings
    ) {
        ContractMetrics metrics = new ContractMetrics();
        Datetime startDateTime = Datetime.newInstance(contractRecord.TAG_StartDate__c, Time.newInstance(0, 0, 0, 0));
        Datetime exclusiveEndDateTime = Datetime.newInstance(
            contractRecord.TAG_EndDate__c.addDays(1),
            Time.newInstance(0, 0, 0, 0)
        );
        metrics.presentedCandidates = countOutcomes(presentedOutcomes, startDateTime, exclusiveEndDateTime);
        metrics.hiredCandidates = countOutcomes(hiredOutcomes, startDateTime, exclusiveEndDateTime);
        metrics.meetings = countMeetings(meetings, contractRecord.TAG_StartDate__c, contractRecord.TAG_EndDate__c);
        return metrics;
    }

    private static Integer countOutcomes(
        List<CandidateOutcome__c> outcomes,
        Datetime startDateTime,
        Datetime exclusiveEndDateTime
    ) {
        Integer count = 0;
        if (outcomes == null) {
            return count;
        }
        for (CandidateOutcome__c outcome : outcomes) {
            if (outcome.TimeRegistered__c >= startDateTime && outcome.TimeRegistered__c < exclusiveEndDateTime) {
                count++;
            }
        }
        return count;
    }

    private static Integer countMeetings(List<Event> meetings, Date startDate, Date endDate) {
        Integer count = 0;
        if (meetings == null) {
            return count;
        }
        for (Event meeting : meetings) {
            if (meeting.ActivityDate >= startDate && meeting.ActivityDate <= endDate) {
                count++;
            }
        }
        return count;
    }

    private class ContractMetrics {
        private Integer hiredCandidates = 0;
        private Integer presentedCandidates = 0;
        private Integer meetings = 0;
    }

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

    public class ContractMetricsException extends Exception {
    }
}
