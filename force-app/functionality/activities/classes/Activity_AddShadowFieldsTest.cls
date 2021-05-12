@isTest
private without sharing class Activity_AddShadowFieldsTest {
    @isTest
    private static void testShadowPicklistValues() {
        List<Task> tasks = new List<Task>();
        tasks.add(
            new Task(
                TAG_NoPersonInformation__c = true,
                ActivityDate = Date.today(),
                TAG_Service__c = 'IPS Jobbutvikling',
                TAG_ActivityType__c = 'Rekruttere og inkludere',
                Subject = 'test'
            )
        );

        Test.StartTest();
        List<Task> changedTasks = Activity_AddShadowFields.shadowPicklistValues(tasks);
        Test.StopTest();

        System.assertEquals(
            'Rekruttere og inkludere',
            changedTasks[0].TAG_ActivityType_Value__c,
            'should have added the picklist value in the shadow field'
        );
        System.assertEquals(
            'IPS Jobbutvikling',
            changedTasks[0].TAG_Service_Value__c,
            'should have added the picklist value in the shadow field'
        );
    }

    @isTest
    private static void testInsert() {
        List<Task> tasks = new List<Task>();
        tasks.add(
            new Task(
                TAG_NoPersonInformation__c = true,
                ActivityDate = Date.today(),
                TAG_Service__c = 'IPS Jobbutvikling',
                TAG_ActivityType__c = 'Rekruttere og inkludere',
                Subject = 'test'
            )
        );

        Test.StartTest();
        insert tasks;
        Test.StopTest();

        List<Task> insertedTasks = [SELECT TAG_ActivityType_Value__c, TAG_Service_Value__c FROM Task];
        System.assertEquals(1, insertedTasks.size(), 'should only be one task');

        System.assertEquals(
            'Rekruttere og inkludere',
            insertedTasks[0].TAG_ActivityType_Value__c,
            'should have added the picklist value in the shadow field'
        );
        System.assertEquals(
            'IPS Jobbutvikling',
            insertedTasks[0].TAG_Service_Value__c,
            'should have added the picklist value in the shadow field'
        );
    }

    @isTest
    private static void testUpdate() {
        List<Task> tasks = new List<Task>();
        tasks.add(
            new Task(
                TAG_NoPersonInformation__c = true,
                ActivityDate = Date.today(),
                TAG_Service__c = null,
                TAG_ActivityType__c = 'Rekruttere og inkludere',
                Subject = 'test'
            )
        );

        tasks = Activity_AddShadowFields.shadowPicklistValues(tasks);
        insert tasks;

        List<Task> insertedTasks = [
            SELECT TAG_ActivityType_Value__c, TAG_ActivityType__c, TAG_Service__c, TAG_Service_Value__c
            FROM Task
        ];
        System.assertEquals(1, insertedTasks.size(), 'should only be one task');

        System.assertEquals(null, insertedTasks[0].TAG_Service__c, 'should be null because empty');
        System.assertEquals(null, insertedTasks[0].TAG_Service_Value__c, 'should be null because empty');

        Test.StartTest();
        tasks[0].TAG_Service__c = 'IPS Jobbutvikling';
        update tasks;
        Test.StopTest();

        List<Task> updatedTasks = [
            SELECT TAG_ActivityType_Value__c, TAG_ActivityType__c, TAG_Service__c, TAG_Service_Value__c
            FROM Task
        ];
        System.assertEquals(1, updatedTasks.size(), 'should only be one task');

        System.assertEquals(
            'Rekruttere og inkludere',
            updatedTasks[0].TAG_ActivityType__c,
            'should have the same old value'
        );
        System.assertEquals(
            'Rekruttere og inkludere',
            updatedTasks[0].TAG_ActivityType_Value__c,
            'should have added the picklist value in the shadow field'
        );
        System.assertEquals('IPS Jobbutvikling', updatedTasks[0].TAG_Service__c, 'should have the same old value');
        System.assertEquals(
            'IPS Jobbutvikling',
            updatedTasks[0].TAG_Service_Value__c,
            'should have added the picklist value in the shadow field'
        );
    }
}
