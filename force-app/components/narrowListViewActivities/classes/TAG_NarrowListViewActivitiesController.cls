public with sharing class TAG_NarrowListViewActivitiesController {
    public class TaskListResult {
        @AuraEnabled public List<Task> records;
        @AuraEnabled public Integer count;
    }

    public class EventListResult {
        @AuraEnabled public List<Event> records;
        @AuraEnabled public Integer count;
    }

    @AuraEnabled
    public static void closeTask(Id taskId) {
    Task t = new Task(Id = taskId, Status = 'Completed');
    update t;
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
                WhatId,
                What.Name,
                What.Type,
                WhoId,
                Who.Name,
                ActivityDate, 
                RelatedToAccount__c,
                RelatedToAccount__r.Name
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

    @AuraEnabled(cacheable=true)
        public static EventListResult fetchOpenEvents(Integer limitSize) {
        Date today = Date.today();
        Datetime start = Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0));

        Datetime endDate = start.addDays(90);

        List<Event> events = [
            SELECT Id,
                Subject,
                WhoId,
                WhatId,
                LastModifiedDate,
                CreatedDate,
                OwnerId,
                ActivityDate,
                StartDateTime,
                EndDateTime,
                RelatedToAccount__c,
                RelatedToAccount__r.Name
            FROM Event
            WHERE StartDateTime >= :start
            AND StartDateTime <= :endDate
            AND OwnerId = :UserInfo.getUserId()
            ORDER BY StartDateTime ASC
            LIMIT :limitSize
        ];

        EventListResult result = new EventListResult();
        result.records = events;
        result.count = events.size();
        return result;
    }

    public class RecordTypeDto {
        @AuraEnabled public String developerName;
        @AuraEnabled public String id;
        public RecordTypeDto(String developerName, String id) {
            this.developerName = developerName;
            this.id = id;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordTypeDto> getIaRecordTypeIds() {
        List<RecordTypeDto> out = new List<RecordTypeDto>();
        for (RecordType rt : [
            SELECT Id, DeveloperName, SObjectType
            FROM RecordType
            WHERE SObjectType IN ('Task','Event')
              AND DeveloperName IN ('IA_task','IA_event')
        ]) {
            out.add(new RecordTypeDto(rt.DeveloperName, String.valueOf(rt.Id)));
        }
        return out;
    }
}