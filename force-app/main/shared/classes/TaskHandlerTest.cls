@isTest
private without sharing class TaskHandlerTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.assignPermissionSet('accountTypeHandler@nav.test', 'ManageAccounts');
    }

    @isTest
    private static void testTaskOnAfterInsert() {
        List<Account> acc = TAG_TestDataFactory.createAccounts(1);
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test');

        Test.StartTest();
        List<Task> taskShadowsData = new List<Task>();

        for (Integer i = 0; i < 200; i++) {
            taskShadowsData.add(
                new Task(
                    WhatId = acc[0].Id,
                    WhoId = c.Id,
                    TAG_NoPersonInformation__c = true,
                    Subject = 'testSubject',
                    TAG_ActivityType__c = 'Rekruttere og inkludere'
                )
            );
        }
        insert taskShadowsData;
        Test.StopTest();

        List<EventShadow__c> es = [SELECT Id, SH_TaskId__c FROM EventShadow__c];
        Integer TaskShadowCount = es.size();

        System.assertEquals(200, TaskShadowCount);
    }

    @isTest
    private static void testTaskOnAfterUpdate() {
        List<Account> acc = TAG_TestDataFactory.createAccounts(1);
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test');
        Task e = new Task(
            WhatId = acc[0].Id,
            WhoId = c.Id,
            TAG_NoPersonInformation__c = true,
            Subject = 'testSubject',
            TAG_ActivityType__c = 'Rekruttere og inkludere'
        );
        insert e;

        Test.StartTest();
        e.Subject = 'Subject Updated';
        update e;
        Test.StopTest();

        List<EventShadow__c> es = [SELECT Id, SH_TaskId__c, SH_Subject__c FROM EventShadow__c];
        Integer TaskShadowCount = es.size();

        System.assertEquals(1, TaskShadowCount);
        System.assertEquals(e.Id, es[0].SH_TaskId__c);
        System.assertEquals('Subject Updated', es[0].SH_Subject__c);
    }

    @isTest
    private static void testTaskOnAfterDelete() {
        List<Account> acc = TAG_TestDataFactory.createAccounts(1);
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test');
        Task e = new Task(
            WhatId = acc[0].Id,
            WhoId = c.Id,
            TAG_NoPersonInformation__c = true,
            Subject = 'testSubject',
            TAG_ActivityType__c = 'Rekruttere og inkludere'
        );
        insert e;

        EventShadow__c eu = new EventShadow__c(SH_TaskId__c = e.id);
        upsert eu SH_TaskId__c;

        List<EventShadow__c> es = [SELECT Id FROM EventShadow__c];
        Integer TaskShadowCount = es.size();

        System.assertEquals(1, TaskShadowCount);

        Test.StartTest();
        delete e;
        Test.StopTest();

        List<EventShadow__c> esUpd = [SELECT Id FROM EventShadow__c];
        Integer TaskShadowCountUpd = esUpd.size();

        System.assertEquals(0, TaskShadowCountUpd);
    }

    @isTest
    private static void testTaskOnAfterUndelete() {
        List<Account> acc = TAG_TestDataFactory.createAccounts(1);
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test');
        Task e = new Task(
            WhatId = acc[0].Id,
            WhoId = c.Id,
            TAG_NoPersonInformation__c = true,
            Subject = 'testSubject',
            TAG_ActivityType__c = 'Rekruttere og inkludere'
        );
        insert e;
        Id taskId = e.Id;

        List<EventShadow__c> es = [SELECT Id FROM EventShadow__c];
        Integer TaskShadowCount = es.size();
        System.assertEquals(1, TaskShadowCount);

        Test.StartTest();
        delete e;
        Task eu = [SELECT Id FROM Task WHERE Id = :taskId ALL ROWS];
        undelete eu;
        Test.StopTest();

        List<EventShadow__c> esUnd = [SELECT Id FROM EventShadow__c];
        Integer TaskShadowCountUnd = esUnd.size();

        System.assertEquals(1, TaskShadowCountUnd);
    }
}
