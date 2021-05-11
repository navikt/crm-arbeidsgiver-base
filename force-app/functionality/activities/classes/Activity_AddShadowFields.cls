public with sharing class Activity_AddShadowFields {
    global override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        shadowPicklistValues((List<Task>) records);
    }

    global override void onBeforeInsert() {
        shadowPicklistValues((List<Task>) records);
    }

    public static List<Task> shadowPicklistValues(List<Task> tasks) {
        for (Task t : tasks) {
            t.TAG_ActivityType_Value__c = t.TAG_ActivityType__c;
            t.TAG_Service_Value__c = t.TAG_Service__c;
        }

        return tasks;
    }
}
