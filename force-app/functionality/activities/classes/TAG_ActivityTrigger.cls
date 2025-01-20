/**
 * @description Trigger that fires on all actions on Task and Event. The trigger creates a new platform event by
 * creating new EmployerActivityEvent__e records. Uses utilities and framework provided
 * by the MyTriggers class combined with MyTrigger setup in Custom Metadata
 *
 * @author Andre Colle <andre.colle@nav.no>
 * @since 2025-01-14 Created.
 */
global class TAG_ActivityTrigger extends MyTriggers {
    static final String EVENT_TYPE_DELETED = 'Deleted';
    static final String EVENT_TYPE_CREATED = 'Created';
    static final String EVENT_TYPE_UPDATED = 'Updated';
    static final String EVENT_TYPE_UNDELETED = 'Undeleted';

    /**
     * @description Method tiggered by after deletion activities
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-16 Created.
     * 
     * @param records List of SObject with the triggered records
     */
    global override void onAfterDelete() {
        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helper = new TAG_ActivityTriggerHelper();

        for (SObject record : records) {
            if (record instanceof Task) {
                Task task = (Task) record;

                taskEmployerActivityList = helper.createEmployerActivityEventForTask(
                    EVENT_TYPE_DELETED, task
                );
            }
            if (record instanceof Event) {
                Event event = (Event) record;

                eventEmployerActivityList = helper.createEmployerActivityEventForEvent(
                    EVENT_TYPE_DELETED, event
                );
            }
        }
        if (!taskEmployerActivityList.isEmpty()) {
            EventBus.publish(taskEmployerActivityList);
        }
        if (!eventEmployerActivityList.isEmpty()) {
            EventBus.publish(eventEmployerActivityList);
        }
    }

     /**
     * @description Method tiggered by after insertion/create of activities
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-16 Created.
     * 
     * @param records List of SObject with the triggered records
     */
   /* global override void onAfterInsert() {
        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helper = new TAG_ActivityTriggerHelper();

        for (SObject record : records) {
            if (record instanceof Task) {
                Task task = (Task) record;

                taskEmployerActivityList = helper.createEmployerActivityEventForTask(
                    EVENT_TYPE_CREATED, task
                );
            }
            if (record instanceof Event) {
                Event event = (Event) record;

                eventEmployerActivityList = helper.createEmployerActivityEventForEvent(
                    EVENT_TYPE_CREATED, event
                );
            }
        }
        if (!taskEmployerActivityList.isEmpty()) {
            EventBus.publish(taskEmployerActivityList);
        }
        if (!eventEmployerActivityList.isEmpty()) {
            EventBus.publish(eventEmployerActivityList);
        }
    } */

    /**
     * @description Method tiggered by after update of activities
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-16 Created.
     * 
     * @param records List of SObject with the triggered records
     */
    /*global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helper = new TAG_ActivityTriggerHelper();


        for (SObject record : records) {
            if (record instanceof Task) {
                Task task = (Task) record;

                taskEmployerActivityList = helper.createEmployerActivityEventForTask(
                    EVENT_TYPE_UPDATED, task
                );
            }
            if (record instanceof Event) {
                Event event = (Event) record;

                eventEmployerActivityList = helper.createEmployerActivityEventForEvent(
                    EVENT_TYPE_UPDATED, event
                );
            }
        }
        if (!taskEmployerActivityList.isEmpty()) {
            EventBus.publish(taskEmployerActivityList);
        }
        if (!eventEmployerActivityList.isEmpty()) {
            EventBus.publish(eventEmployerActivityList);
        } 
    }*/

    /**
     * @description Method tiggered by after undeletion of activities
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-16 Created.
     * 
     * @param records List of SObject with the triggered records
     */
    global override void onAfterUndelete() { 
        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helper = new TAG_ActivityTriggerHelper();

        for (SObject record : records) {
            if (record instanceof Task) {
                Task task = (Task) record;

                taskEmployerActivityList = helper.createEmployerActivityEventForTask(
                    EVENT_TYPE_UNDELETED, task
                );
            }
            if (record instanceof Event) {
                Event event = (Event) record;

                eventEmployerActivityList = helper.createEmployerActivityEventForEvent(
                    EVENT_TYPE_UNDELETED, event
                );
            }
        }
        if (!taskEmployerActivityList.isEmpty()) {
            EventBus.publish(taskEmployerActivityList);
        }
        if (!eventEmployerActivityList.isEmpty()) {
            EventBus.publish(eventEmployerActivityList);
        }
    }
}