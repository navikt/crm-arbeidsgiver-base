global class TaskHandler extends MyTriggers {
    global override void onAfterInsert() {
        upsertTaskShadow((List<Task>) records);
    }

    global override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
        upsertTaskShadow((List<Task>) records);
    }

    global override void onAfterDelete() {
        deleteTaskShadow((List<Task>) records);
    }

    global override void onAfterUndelete() {
        upsertTaskShadow((List<Task>) records);
    }

    public static EventShadow__c createTaskShadowObject(Task e) {
        EventShadow__c es = new EventShadow__c();
        es.SH_AccountOrgNumber__c = e.CRM_AccountOrgNumber__c;
        es.SH_AccountParentId__c = e.TAG_AccountParentId__c;
        es.SH_AccountParentOrgNumber__c = e.TAG_AccountParentOrgNumber__c;
        es.SH_AccountOrgType__c = e.TAG_AccountOrgType__c;
        es.SH_AccountNAVUnit__c = e.TAG_AccountNAVUnit__c;
        es.SH_UserNAVUnit__c = e.TAG_UserNAVUnit__c;
        es.SH_ActivityType__c = e.TAG_ActivityType__c;
        es.SH_CreatedById__c = e.CreatedById;
        es.SH_Date__c = e.ActivityDate;
        es.SH_DateActivity__c = e.Date__c;
        es.SH_LastModifiedById__c = e.LastModifiedById;
        es.SH_NoPersonalInformation__c = e.TAG_NoPersonInformation__c;
        es.SH_OwnerId__c = e.OwnerId;
        es.SH_Region__c = e.CRM_Region__c;
        es.SH_RelatedToAccount__c = e.AccountId;
        es.SH_Service__c = e.TAG_service__c;
        es.SH_Status__c = e.Status;
        es.SH_Subject__c = e.Subject;
        es.SH_TaskEvent__c = e.TaskEvent__c;
        es.SH_Type__c = e.Type;
        es.SH_Unit__c = e.CRM_Unit__c;
        es.SH_WhatId__c = e.WhatId;
        es.SH_WhoId__c = e.WhoId;
        es.SH_EventId__c = e.Id;
        es.SH_TaskId__c = e.Id;
        es.SH_LastModifiedDate__c = e.LastModifiedDate;
        es.SH_CreatedDate__c = e.CreatedDate;
        es.SH_Priority__c = e.Priority;
        es.SH_IsClosed__c = e.IsClosed;
        es.SH_IsArchived__c = e.IsArchived;
        es.SH_TaskSubtype__c = e.TaskSubtype;
        es.SH_CompletedDateTime__c = e.CompletedDateTime;
        es.SH_ReminderDateTime__c = e.ReminderDateTime;

        return es;
    }

    private void deleteTaskShadow(List<Task> tasks) {
        Set<Id> idForDeletion = new Set<Id>();
        for (Task e : tasks) {
            idForDeletion.add(e.Id);
        }
        delete [SELECT Id FROM EventShadow__c WHERE SH_TaskId__c IN :idForDeletion];
    }

    private void upsertTaskShadow(List<Task> tasks) {
        List<EventShadow__c> taskShadows = new List<EventShadow__c>();
        for (Task e : tasks) {
            EventShadow__c es = createTaskShadowObject(e);
            taskShadows.add(es);
        }
        upsert taskShadows SH_TaskId__c;
    }
}
