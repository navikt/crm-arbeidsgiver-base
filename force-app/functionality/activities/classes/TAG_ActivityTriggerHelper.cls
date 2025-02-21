/**
* @description Helper class to TAG_ActivityTrigger trigger class
 *
 * @author Andre Colle <andre.colle@nav.no>
 * @since 2025-01-14 Created.
 */
public with sharing class TAG_ActivityTriggerHelper {

    /**
     * @description Method that creates a new platform event record (EmployerActivityEvent__e) based on input from a Task record
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-14 Created.
     *
     * @param EventType Contains the value of what action that has caused the trigger. Can be deleted, inserted, updated or undeleted
     * @param task Contains task records that have been triggered by delete, insert, update or undelete
     * @return List<EmployerActivityEvent__e>
     */
    public List<EmployerActivityEvent__e> createEmployerActivityEventForTask(String EventType, Task task) {
        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        Set<Id> recordTypes = getRecordTypeIds();

        if (recordTypes.contains(task.RecordTypeId)) {

            //Create EmployerActivityEvent__e record to trigger platform event
            EmployerActivityEvent__e taskEmpActEv = new EmployerActivityEvent__e();
            taskEmpActEv.EventObject__c = 'Task';
            taskEmpActEv.EventType__c = EventType;
            taskEmpActEv.AccountNavUnit__c = task.TAG_AccountNAVUnit__c;
            taskEmpActEv.AccountOrgNumber__c = task.CRM_AccountOrgNumber__c;
            taskEmpActEv.AccountOrgType__c = task.TAG_AccountOrgType__c;
            taskEmpActEv.AccountParentId__c = task.TAG_AccountParentId__c;
            taskEmpActEv.AccountParentOrgNumber__c = task.TAG_AccountParentOrgNumber__c;
            taskEmpActEv.ActivityDate__c = task.ActivityDate;
            taskEmpActEv.ActivityType__c = task.TAG_ActivityType__c;
            taskEmpActEv.ActivityCreatedDate__c = task.CreatedDate;
            taskEmpActEv.CompletedDate__c = task.TAG_CompletedDate__c;
            taskEmpActEv.IACaseNumber__c = task.TAG_IACaseNumber__c;
            taskEmpActEv.IACooperationId__c = task.TAG_IACooperationId__c;
            taskEmpActEv.IASubtheme__c = task.IASubtheme__c;
            taskEmpActEv.Id__c = task.Id;
            taskEmpActEv.LastModifiedById__c = task.LastModifiedById;
            taskEmpActEv.LastModifiedDate__c = task.LastModifiedDate;
            taskEmpActEv.OwnerId__c = task.OwnerId;
            taskEmpActEv.Priority__c = task.Priority;
            taskEmpActEv.RecordTypeId__c = task.RecordTypeId;
            taskEmpActEv.RecordTypeName__c = task.RecordTypeName__c;
            taskEmpActEv.Region__c = task.CRM_Region__c;
            taskEmpActEv.ReminderDateTime__c = task.ReminderDateTime;
            taskEmpActEv.Service__c = task.TAG_service__c;
            taskEmpActEv.Status__c = task.TAG_Status__c;
            taskEmpActEv.Subject__c = task.Subject;
            taskEmpActEv.TaskEvent__c = task.TaskEvent__c;
            taskEmpActEv.Type__c = task.Type;
            taskEmpActEv.Unit__c = task.CRM_Unit__c;
            taskEmpActEv.UserNavUnit__c = task.TAG_UserNAVUnit__c;
            taskEmpActEv.WhatId__c = task.WhatId;
            taskEmpActEv.WhoId__c = task.WhoId;

            if (EventType == 'Deleted'){
                taskEmpActEv.DeletedDate__c = task.LastModifiedDate;
            }

            taskEmployerActivityList.add(taskEmpActEv);
        }
        return taskEmployerActivityList;
    }

     /**
     * @description Method that creates a new platform event record (EmployerActivityEvent__e) based on input from a Event record
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-14 Created.
     *
     * @param EventType Contains the value of what action that has caused the trigger. Can be deleted, inserted, updated or undeleted
     * @param event Contains task records that have been triggered by delete, insert, update or undelete
     * @return List<EmployerActivityEvent__e>
     */
    public List<EmployerActivityEvent__e> createEmployerActivityEventForEvent(String EventType, Event event) {
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();
        Set<Id> recordTypes = getRecordTypeIds();

        if (recordTypes.contains(event.RecordTypeId)) {

            //Create EmployerActivityEvent__e record to trigger platform event
            EmployerActivityEvent__e eventEmpActEv = new EmployerActivityEvent__e();
            eventEmpActEv.EventObject__c = 'Event';
            eventEmpActEv.EventType__c = EventType;
            eventEmpActEv.AccountNavUnit__c = event.TAG_AccountNAVUnit__c;
            eventEmpActEv.AccountOrgNumber__c = event.CRM_AccountOrgNumber__c;
            eventEmpActEv.AccountOrgType__c = event.TAG_AccountOrgType__c;
            eventEmpActEv.AccountParentId__c = event.TAG_AccountParentId__c;
            eventEmpActEv.AccountParentOrgNumber__c = event.TAG_AccountParentOrgNumber__c;
            eventEmpActEv.ActivityDate__c = event.ActivityDate;
            eventEmpActEv.ActivityType__c = event.TAG_ActivityType__c;
            eventEmpActEv.ActivityCreatedDate__c = event.CreatedDate;
            eventEmpActEv.DurationInMinutes__c = event.DurationInMinutes;
            eventEmpActEv.EndDateTime__c = event.EndDateTime;
            eventEmpActEv.IACaseNumber__c = event.TAG_IACaseNumber__c;
            eventEmpActEv.IACooperationId__c = event.TAG_IACooperationId__c;
            eventEmpActEv.IASubtheme__c = event.IASubtheme__c;
            eventEmpActEv.Id__c = event.Id;
            eventEmpActEv.LastModifiedById__c = event.LastModifiedById;
            eventEmpActEv.LastModifiedDate__c = event.LastModifiedDate;
            eventEmpActEv.OwnerId__c = event.OwnerId;
            eventEmpActEv.RecordTypeId__c = event.RecordTypeId;
            eventEmpActEv.RecordTypeName__c = event.RecordTypeName__c;
            eventEmpActEv.Region__c = event.CRM_Region__c;
            eventEmpActEv.ReminderDateTime__c = event.ReminderDateTime;
            eventEmpActEv.Service__c = event.TAG_service__c;
            eventEmpActEv.StartDateTime__c = event.StartDateTime;
            eventEmpActEv.Status__c = event.TAG_Status__c;
            eventEmpActEv.Subject__c = event.Subject;
            eventEmpActEv.TaskEvent__c = event.TaskEvent__c;
            eventEmpActEv.Type__c = event.Type;
            eventEmpActEv.Unit__c = event.CRM_Unit__c;
            eventEmpActEv.UserNavUnit__c = event.TAG_UserNAVUnit__c;
            eventEmpActEv.WhatId__c = event.WhatId;
            eventEmpActEv.WhoId__c = event.WhoId;

            if (EventType == 'Deleted'){
                eventEmpActEv.DeletedDate__c = event.LastModifiedDate;
            }

            eventEmployerActivityList.add(eventEmpActEv);
        }
        return eventEmployerActivityList;
    }

     /**
     * @description Method that finds all event and task record types that are available for the Salesforce Arbeidsgiver users
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-14 Created.
     *
     * @return Set<Id> containing all the id's of the available record types
     */
    private static Set<Id> getRecordTypeIds() {
        Set<Id> recordTypeIds = new Set<Id>();
    
        recordTypeIds.add(
            Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverEvent').getRecordTypeId()
        );
        recordTypeIds.add(
            Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('IA_event').getRecordTypeId()
        );
        recordTypeIds.add(
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverTask').getRecordTypeId()
        );
         recordTypeIds.add(
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('IA_task').getRecordTypeId()
        );
        /* recordTypeIds.add(
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('IPS_UO_Arbeidsgiver').getRecordTypeId()
        ); */
    
        return recordTypeIds;
      }
}