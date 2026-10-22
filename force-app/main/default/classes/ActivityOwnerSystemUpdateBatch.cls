/**
 * Sets the system-update marker on selected Task or Event records.
 * The existing before-save flows refresh owner-derived fields when the marker is set.
 */
public with sharing class ActivityOwnerSystemUpdateBatch implements Database.Batchable<SObject> {
    private final Integer recordLimit;
    private final String recordTypeDeveloperName;
    private final Set<String> validRecordTypes = new Set<String>{
        'ArbeidsgiverTask',
        'IA_task',
        'ArbeidsgiverEvent',
        'IA_event'
    };

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

        queryString += ' AND TAG_OwnerRegion__c = NULL AND ActivityDate >= LAST_N_DAYS:365';
        queryString += ' WITH USER_MODE ORDER BY WhatId, AccountId';
        if (this.recordLimit != null && this.recordLimit > 0) {
            queryString += ' LIMIT ' + this.recordLimit;
        }

        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (SObject activity : scope) {
            activity.put('TAG_IsSystemUpdate__c', true);
        }

        Database.SaveResult[] results = Database.update(scope, false, AccessLevel.USER_MODE);
    }

    public void finish(Database.BatchableContext context) {
    }
}
