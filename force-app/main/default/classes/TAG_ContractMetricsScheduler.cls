/**
 * Scheduling entry point for contract metric recalculation.
 */
public with sharing class TAG_ContractMetricsScheduler implements Schedulable {
    private static final Integer BATCH_SIZE = 200;

    /**
     * Starts the contract metrics batch.
     * @param context Scheduling context.
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new TAG_ContractMetricsBatch(), BATCH_SIZE);
    }
}