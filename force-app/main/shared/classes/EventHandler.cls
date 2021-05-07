global class EventHandler extends MyTriggers {
    global override void onAfterInsert() {
        upsertEventShadow((List<Event>) records);
    }

    global override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
        upsertEventShadow((List<Event>) records);
    }

    global override void onAfterDelete() {
        deleteEventShadow((List<Event>) records);
    }

    global override void onAfterUndelete() {
        upsertEventShadow((List<Event>) records);
    }

    public static EventShadow__c createEventShadowObject(Event e) {
        EventShadow__c es = new EventShadow__c();
        es.SH_AccountOrgNumber__c = e.CRM_AccountOrgNumber__c;
        es.SH_AccountParentId__c = e.TAG_AccountParentId__c;
        es.SH_AccountParentOrgNumber__c = e.TAG_AccountParentOrgNumber__c;
        es.SH_AccountOrgType__c = e.TAG_AccountOrgType__c;
        es.SH_AccountNAVUnit__c = e.TAG_AccountNAVUnit__c;
        es.SH_UserNAVUnit__c = e.TAG_UserNAVUnit__c;
        es.SH_ActivityDateTime__c = e.ActivityDateTime;
        es.SH_ActivityType__c = e.TAG_ActivityType__c;
        es.SH_CreatedById__c = e.CreatedById;
        es.SH_Date__c = e.ActivityDate;
        es.SH_DateActivity__c = e.Date__c;
        es.SH_DurationTime__c = e.DurationInMinutes;
        es.SH_EndDateTime__c = e.EndDateTime;
        es.SH_EventSubtype__c = e.EventSubtype;
        es.SH_LastModifiedById__c = e.LastModifiedById;
        es.SH_NoPersonalInformation__c = e.TAG_NoPersonInformation__c;
        es.SH_OwnerId__c = e.OwnerId;
        es.SH_Region__c = e.CRM_Region__c;
        es.SH_RelatedToAccount__c = e.AccountId;
        es.SH_Service__c = e.TAG_service__c;
        es.SH_StartDateTime__c = e.StartDateTime;
        es.SH_Status__c = e.TAG_Status__c;
        es.SH_Subject__c = e.Subject;
        es.SH_TaskEvent__c = e.TaskEvent__c;
        es.SH_Type__c = e.Type;
        es.SH_Unit__c = e.CRM_Unit__c;
        es.SH_WhatId__c = e.WhatId;
        es.SH_WhoId__c = e.WhoId;
        es.SH_EventId__c = e.Id;

        return es;
    }

    private void deleteEventShadow(List<Event> events) {
        Set<Id> idForDeletion = new Set<Id>();
        for (Event e : events) {
            idForDeletion.add(e.Id);
        }
        delete [SELECT Id FROM EventShadow__c WHERE SH_EventId__c IN :idForDeletion];
    }

    private void upsertEventShadow(List<Event> events) {
        List<EventShadow__c> eventShadows = new List<EventShadow__c>();
        for (Event e : events) {
            EventShadow__c es = createEventShadowObject(e);
            eventShadows.add(es);
        }
        upsert eventShadows SH_EventId__c;
    }
}
