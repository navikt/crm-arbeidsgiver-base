global class EventHandler extends MyTriggers {

	global override void onAfterInsert() {
		createEventShadow( (List<Event>) records );
    }
    
    global override void onAfterUpdate( Map<Id, SObject> triggerOldMap ) {
        updateEventShadow( (List<Event>) records);
    }

    global override void onAfterDelete() {
        deleteEventShadow( (List<Event>) records );
    }

    global override void onAfterUndelete() {
        undeleteEventShadow( (List<Event>) records );
    }

    private void createEventShadow( List<Event> events ) {

        for(Event e : events ) {
        
        EventShadow__c es = new EventShadow__c();
        es.SH_AccountOrgNumber__c=e.CRM_AccountOrgNumber__c;
        es.SH_AccountParentId__c=e.TAG_AccountParentId__c;
        es.SH_AccountParentOrgNumber__c=e.TAG_AccountParentOrgNumber__c;
        es.SH_ActivityDateTime__c=e.ActivityDateTime;
        es.SH_ActivityType__c=e.TAG_ActivityType__c;
        es.SH_CreatedById__c=e.CreatedById;
        es.SH_Date__c=e.ActivityDate;
        es.SH_DateActivity__c=e.Date__c;
        es.SH_DurationTime__c=e.DurationInMinutes;
        es.SH_EndDateTime__c=e.EndDateTime;
        es.SH_EventSubtype__c=e.EventSubtype;
        es.SH_LastModifiedById__c=e.LastModifiedById;
        es.SH_NoPersonalInformation__c=e.TAG_NoPersonInformation__c;
        es.SH_OwnerId__c=e.OwnerId;
        es.SH_Region__c=e.CRM_Region__c;
        es.SH_RelatedToAccount__c=e.RelatedToAccount__c;
        es.SH_Service__c=e.TAG_service__c;
        es.SH_StartDateTime__c=e.StartDateTime;
        es.SH_Status__c=e.TAG_Status__c;
        es.SH_Subject__c=e.Subject;
        es.SH_TaskEvent__c=e.TaskEvent__c;
        es.SH_Type__c=e.Type;
        es.SH_Unit__c=e.CRM_Unit__c;
        es.SH_WhatId__c=e.WhatId;
        es.SH_WhoId__c=e.WhoId;
        es.SH_EventId__c=e.Id;

        Insert es;
        }
    }

    private void updateEventShadow( List<Event> events ) {

        Set<String> allIds = new Set<String>();
        for (Event e : events){
            allIds.add(e.Id);
        }

        List<EventShadow__c> listEs = [SELECT Id, SH_AccountOrgNumber__c,SH_AccountParentId__c,SH_AccountParentOrgNumber__c,SH_ActivityDateTime__c,SH_ActivityType__c,SH_CreatedById__c,SH_DateActivity__c,SH_Date__c,SH_DurationTime__c,SH_EndDateTime__c,SH_EventId__c,SH_EventSubtype__c,SH_LastModifiedById__c,SH_NoPersonalInformation__c,SH_OwnerId__c,SH_Region__c,SH_RelatedToAccount__c,SH_Service__c,SH_StartDateTime__c,SH_Status__c,SH_Subject__c,SH_TaskEvent__c,SH_Type__c,SH_Unit__c,SH_WhatId__c,SH_WhoId__c FROM EventShadow__c WHERE SH_EventId__c IN :allIds];

        Map<String, EventShadow__c> eventIdToEventShadow = new Map<String, EventShadow__c>();
        for(EventShadow__c es : listEs) {
            eventIdToEventShadow.put(es.SH_EventId__c, es);
        }
        for(Event e : events) {
            EventShadow__c esRecord = eventIdToEventShadow.get(e.Id);
            if (esRecord != null) {
                esRecord.SH_AccountOrgNumber__c=e.CRM_AccountOrgNumber__c;
                esRecord.SH_AccountParentId__c=e.TAG_AccountParentId__c;
                esRecord.SH_AccountParentOrgNumber__c=e.TAG_AccountParentOrgNumber__c;
                esRecord.SH_ActivityDateTime__c=e.ActivityDateTime;
                esRecord.SH_ActivityType__c=e.TAG_ActivityType__c;
                esRecord.SH_CreatedById__c=e.CreatedById;
                esRecord.SH_Date__c=e.ActivityDate;
                esRecord.SH_DateActivity__c=e.Date__c;
                esRecord.SH_DurationTime__c=e.DurationInMinutes;
                esRecord.SH_EndDateTime__c=e.EndDateTime;
                esRecord.SH_EventSubtype__c=e.EventSubtype;
                esRecord.SH_LastModifiedById__c=e.LastModifiedById;
                esRecord.SH_NoPersonalInformation__c=e.TAG_NoPersonInformation__c;
                esRecord.SH_OwnerId__c=e.OwnerId;
                esRecord.SH_Region__c=e.CRM_Region__c;
                esRecord.SH_RelatedToAccount__c=e.RelatedToAccount__c;
                esRecord.SH_Service__c=e.TAG_service__c;
                esRecord.SH_StartDateTime__c=e.StartDateTime;
                esRecord.SH_Status__c=e.TAG_Status__c;
                esRecord.SH_Subject__c=e.Subject;
                esRecord.SH_TaskEvent__c=e.TaskEvent__c;
                esRecord.SH_Type__c=e.Type;
                esRecord.SH_Unit__c=e.CRM_Unit__c;
                esRecord.SH_WhatId__c=e.WhatId;
                esRecord.SH_WhoId__c=e.WhoId;
                esRecord.SH_EventId__c=e.Id;
            }
            Update esRecord;
        }
    }

    private void deleteEventShadow( List<Event> events ) {
        
        Set<String> idForDeletion = new Set<String>();
        for (Event e : events){
            idForDeletion.add(e.Id);
        }
        List<EventShadow__c> listDeleted = [SELECT Id FROM EventShadow__c WHERE SH_EventId__c IN :idForDeletion];

        delete listDeleted;

    }

    private void undeleteEventShadow( List<Event> events ){
        for(Event e : events ) {
        
            EventShadow__c es = new EventShadow__c();
            es.SH_AccountOrgNumber__c=e.CRM_AccountOrgNumber__c;
            es.SH_AccountParentId__c=e.TAG_AccountParentId__c;
            es.SH_AccountParentOrgNumber__c=e.TAG_AccountParentOrgNumber__c;
            es.SH_ActivityDateTime__c=e.ActivityDateTime;
            es.SH_ActivityType__c=e.TAG_ActivityType__c;
            es.SH_CreatedById__c=e.CreatedById;
            es.SH_Date__c=e.ActivityDate;
            es.SH_DateActivity__c=e.Date__c;
            es.SH_DurationTime__c=e.DurationInMinutes;
            es.SH_EndDateTime__c=e.EndDateTime;
            es.SH_EventSubtype__c=e.EventSubtype;
            es.SH_LastModifiedById__c=e.LastModifiedById;
            es.SH_NoPersonalInformation__c=e.TAG_NoPersonInformation__c;
            es.SH_OwnerId__c=e.OwnerId;
            es.SH_Region__c=e.CRM_Region__c;
            es.SH_RelatedToAccount__c=e.RelatedToAccount__c;
            es.SH_Service__c=e.TAG_service__c;
            es.SH_StartDateTime__c=e.StartDateTime;
            es.SH_Status__c=e.TAG_Status__c;
            es.SH_Subject__c=e.Subject;
            es.SH_TaskEvent__c=e.TaskEvent__c;
            es.SH_Type__c=e.Type;
            es.SH_Unit__c=e.CRM_Unit__c;
            es.SH_WhatId__c=e.WhatId;
            es.SH_WhoId__c=e.WhoId;
            es.SH_EventId__c=e.Id;
    
            Insert es;
            }
    }
}