public with sharing class TAG_NarrowListViewActivitiesController {
    public class TaskListResult {
        @AuraEnabled public List<Task> records;
        @AuraEnabled public Integer count;
    }

    @AuraEnabled(cacheable=true)
    public static TaskListResult fetchOpenTasks(Integer limitSize) {
        // total count of open Tasks for current user
        AggregateResult agg = [
            SELECT count(Id) cnt
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
              AND IsClosed = false
        ];

        Integer total = (Integer)agg.get('cnt');

        List<Task> tasks = [
            SELECT 
                Id,
                Subject,
                Status,
                WhatId, What.Name,
                WhoId,  Who.Name
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
              AND IsClosed = false
            ORDER BY CreatedDate DESC
            LIMIT :limitSize
        ];

        // package into wrapper
        TaskListResult result = new TaskListResult();
        result.records = tasks;
        result.count   = total;
        return result;
    }
}