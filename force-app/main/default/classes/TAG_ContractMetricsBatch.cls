/**
 * Recalculates candidate and meeting metrics for eligible contracts.
 */
public with sharing class TAG_ContractMetricsBatch implements Database.Batchable<SObject> {
    /**
     * Selects contracts eligible for metric calculation.
     * @param context Batch context.
     * @return Query locator for eligible contracts.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE
                    TAG_Status__c IN ('Godkjent', 'AVSLUTTET')
                    AND TAG_Account__c != NULL
                    AND TAG_StartDate__c != NULL
                    AND TAG_EndDate__c != NULL
            ]
        );
    }

    /**
     * Calculates and persists changed metric values for one scope.
     * @param context Batch context.
     * @param scope Contracts in the current scope.
     */
    public void execute(Database.BatchableContext context, List<Contract__c> scope) {
        TAG_ContractMetricsService.applyChanges(scope);
    }

    /**
     * Completes the batch without additional processing.
     * @param context Batch context.
     */
    public void finish(Database.BatchableContext context) {
        return;
    }
}