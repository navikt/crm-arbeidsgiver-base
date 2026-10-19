/**
 * Sets the system-update marker on selected Task or Event records.
 * The existing before-save flows refresh owner-derived fields when the marker is set.
 */
public with sharing class ActivityOwnerSystemUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {
    private final Integer recordLimit;
    private final String recordTypeDeveloperName;
    private final Set<String> validRecordTypes = new Set<String>{
        'ArbeidsgiverTask',
        'IA_task',
        'ArbeidsgiverEvent',
        'IA_event'
    };
    @TestVisible
    private Integer failedRecordCount = 0;
    private String firstFailureMessage;

    /**
     * Creates a batch for the selected activity type and filters.
     * @param recordTypeDeveloperName One of IA Task, IA Event, AG Task, or AG Event.
     * @param recordLimit Optional maximum number of records to query.
     */
    public ActivityOwnerSystemUpdateBatch(String recordTypeDeveloperName, Integer recordLimit) {
        this.recordLimit = recordLimit;
        if (String.isBlank(recordTypeDeveloperName) || !validRecordTypes.contains(recordTypeDeveloperName)) {
            throw new IllegalArgumentException('Unsupported activity type.');
        }
        this.recordTypeDeveloperName = recordTypeDeveloperName;
    }

    /**
     * Defines the matching activity records.
     * @param context Batch context.
     * @return Query locator for matching activities.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        String queryString = 'SELECT Id, TAG_IsSystemUpdate__c';
        if (this.recordTypeDeveloperName.equalsIgnoreCase('ArbeidsgiverTask')) {
            queryString +=
                ' FROM Task WHERE RecordType.DeveloperName = \'ArbeidsgiverTask\' ' +
                'AND TAG_ActivityType__c =\'Rekruttere og inkludere\'';
        } else if (this.recordTypeDeveloperName.equalsIgnoreCase('IA_task')) {
            queryString +=
                ' FROM Task WHERE RecordType.DeveloperName = \'IA_task\' ' +
                'AND TAG_ActivityType__c =\'Forebygge sykefravær og redusere frafall\'';
        } else if (this.recordTypeDeveloperName.equalsIgnoreCase('ArbeidsgiverEvent')) {
            queryString +=
                ' FROM Event WHERE RecordType.DeveloperName = \'ArbeidsgiverEvent\' ' +
                'AND TAG_ActivityType__c =\'Rekruttere og inkludere\'';
        } else if (this.recordTypeDeveloperName.equalsIgnoreCase('IA_event')) {
            queryString +=
                ' FROM Event WHERE RecordType.DeveloperName = \'IA_event\' ' +
                'AND TAG_ActivityType__c =\'Forebygge sykefravær og redusere frafall\'';
        }

        queryString += ' AND (Ansvarlig__c = NULL OR TAG_OwnerMarketRegion__c = NULL OR TAG_OwnerNavUnit__c = NULL OR TAG_OwnerRegion__c = NULL) AND ActivityDate = LAST_N_DAYS:365';

        if (this.recordLimit != null && this.recordLimit > 0) {
            queryString += ' LIMIT ' + this.recordLimit;
        }
        return Database.getQueryLocator(queryString);
    }

    /**
     * Marks each activity for the existing owner-derived field flows.
     * Individual DML failures are recorded and do not prevent later scopes from running.
     * @param context Batch context.
     * @param scope Matching Task or Event records.
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (SObject activity : scope) {
            activity.put('TAG_IsSystemUpdate__c', true);
        }

        Database.SaveResult[] results = Database.update(scope, false);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                failedRecordCount++;
                if (failedRecordCount == 1 && result.getErrors().size() > 0) {
                    Database.Error error = result.getErrors()[0];
                    firstFailureMessage = String.valueOf(error.getStatusCode()) + ': ' + error.getMessage();
                }
            }
        }
    }

    /**
     * Logs a summary when one or more records could not be updated.
     * @param context Batch context.
     */
    public void finish(Database.BatchableContext context) {
        if (failedRecordCount == 0) {
            return;
        }

        LoggerUtility logger = new LoggerUtility();
        logger.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            null,
            'Activity owner refresh failed for ' + failedRecordCount + ' record(s).',
            firstFailureMessage,
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        logger.publish();
    }
}
