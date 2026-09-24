/**
 * Invocable entry point for starting the contract metrics batch from a Flow.
 */
public with sharing class TAG_ContractMetricsBatchInvocable {
    private static final Integer BATCH_SIZE = 200;

    /**
     * Starts the batch that recalculates candidate and meeting metrics for eligible contracts.
     */
    @InvocableMethod(
        label='Start Contract Metrics Batch'
        description='Starts the batch job that recalculates candidate and meeting metrics for eligible contracts.'
        category='Contract (custom)'
    )
    public static void startBatch() {
        Database.executeBatch(new TAG_ContractMetricsBatch(), BATCH_SIZE);
    }
}
