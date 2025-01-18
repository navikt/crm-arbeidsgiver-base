@isTest
public class TAG_ActivityTriggerTest {
    static final String EVENT_TYPE_DELETED = 'Deleted';
    static final String EVENT_TYPE_CREATED = 'Created';
    static final String EVENT_TYPE_UPDATED = 'Updated';
    static final String EVENT_TYPE_UNDELETED = 'Undeleted';

    @testSetup
    static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
             new List<String>{
                'Arbeidsgiver_arenaActivity',
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'Arbeidsgiver_IA'
            } 
        );

        User testUser = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        // Use System.runAs to separate the DML operations
        System.runAs(testUser) {
        Account account = new Account(
            Name = 'test account',
            INT_OrganizationNumber__c = '900888000',
            INT_MunicipalityNumber__c = '3301'
        );
        insert account;

        List<Task> tasks = new List<Task>();
        List<Event> events = new List<Event>();

        for (Integer i = 0; i < 3; i++) {
            Task task = new Task(
                Subject = 'Test Task' + i,
                TAG_ActivityType__c = 'Rekruttere og inkludere',
                //TAG_AccountNAVUnit__c = '0304',
                //CRM_AccountOrgNumber__c = 'Test Org Number',
                //TAG_AccountOrgType__c = 'B' + i,
                //TAG_AccountParentId__c = '201230980',
                //TAG_AccountParentOrgNumber__c = '999000999',
                ActivityDate = Date.today(),
                TAG_IACaseNumber__c = '01J919E4YHKH4K0XSYP2CT0BN2',
                TAG_IACooperationId__c = 'gahdgasd78438',
                IASubtheme__c = 'Oppfølging av arbeidsmiljøundersøkelser',
                TAG_NoPersonInformation__c = true,
                Priority = 'Normal',
                RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverTask').getRecordTypeId(),
                //CRM_Region__c = 'Møre og Romsdal',
                RelatedToAccount__c = account.Id,
                ReminderDateTime = DateTime.now(),
                TAG_service__c = 'Rekruttering (uten virkemidler, inkl. oppfølging)',
                Status = 'Completed',
                //TaskEvent__c = 'Oppgave',
                Type = 'Telefon',
                //CRM_Unit__c = 'Nav Vestfold Telemark og Lofoten',
                //TAG_UserNAVUnit__c = '0304',
                WhatId = account.Id
                //WhoId = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1].Id
            );
            tasks.add(task);

            Event event = new Event(
                Subject = 'Test Event' + i,
                TAG_ActivityType__c = 'Rekruttere og inkludere',
                //TAG_AccountNAVUnit__c = '0304',
                //CRM_AccountOrgNumber__c = 'Test Org Number',
                //TAG_AccountOrgType__c = 'B',
                //TAG_AccountParentId__c = '201230980',
                //TAG_AccountParentOrgNumber__c = '999000999',
                ActivityDate = Date.today(),
                TAG_IACaseNumber__c = '01J919E4YHKH4K0XSYP2CT0BN2',
                TAG_IACooperationId__c = 'gahdgasd78438',
                IASubtheme__c = 'Oppfølging av arbeidsmiljøundersøkelser',
                //DurationInMinutes = 60,
                EndDateTime = DateTime.now().addHours(1),
                TAG_NoPersonInformation__c = true,
                RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverEvent').getRecordTypeId(),
                //CRM_Region__c = 'Møre og Romsdal',
                RelatedToAccount__c = account.Id,
                ReminderDateTime = DateTime.now(),
                TAG_service__c = 'Rekruttering (uten virkemidler, inkl. oppfølging)',
                StartDateTime = DateTime.now(),
                //TAG_Status__c = 'Fullført',
                //TaskEvent__c = 'Møte',
                Type = 'Møte',
                //CRM_Unit__c = 'Nav Vestfold Telemark og Lofoten',
                //TAG_UserNAVUnit__c = '0304',
                WhatId = account.Id
                //WhoId = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1].Id
            );
            events.add(event);
        }
        insert tasks;
        insert events;
    }
}

    @isTest
    static void testOnAfterDelete() {
        List<Task> tasks = [SELECT Id,
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            Priority,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId
            FROM Task LIMIT 1];

        List<Event> events = [SELECT Id, 
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            DurationInMinutes,
            EndDateTime,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            StartDateTime,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId 
            FROM Event LIMIT 1];

        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();
        
        TAG_ActivityTriggerHelper helperTest = new TAG_ActivityTriggerHelper();

        Test.startTest();
        Delete tasks;
        Delete events;
        eventEmployerActivityList = helperTest.createEmployerActivityEventForEvent(EVENT_TYPE_DELETED, events[0]);
        taskEmployerActivityList = helperTest.createEmployerActivityEventForTask(EVENT_TYPE_DELETED, tasks[0]);
        Test.stopTest();

        System.assertEquals(1, taskEmployerActivityList.size(), '1 task platform events should have been published.');
        System.assertEquals(1, eventEmployerActivityList.size(), '1 event platform events should have been published.');
    }
/*
    @isTest
    static void testOnAfterInsert() {
        List<Task> tasks = [SELECT
            ActivityDate,
            Priority,
            RecordTypeId,
            RelatedToAccount__c,
            ReminderDateTime,
            Subject,
            TaskEvent__c,
            Type
            FROM Task LIMIT 1];

        List<Event> events = [SELECT
            ActivityDate,
            EndDateTime,
            RecordTypeId,
            RelatedToAccount__c,
            ReminderDateTime,
            StartDateTime,
            Subject,
            TaskEvent__c,
            Type
            FROM Event LIMIT 1];

        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helperTest = new TAG_ActivityTriggerHelper();

        Test.startTest();
        Insert tasks;
        Insert events;
        eventEmployerActivityList = helperTest.createEmployerActivityEventForEvent(EVENT_TYPE_DELETED, events[0]);
        taskEmployerActivityList = helperTest.createEmployerActivityEventForTask(EVENT_TYPE_DELETED, tasks[0]);
        Test.stopTest();

        System.assertEquals(1, taskEmployerActivityList.size(), '1 task platform events should have been published.');
        System.assertEquals(1, eventEmployerActivityList.size(), '1 event platform events should have been published.');
    }*/

    @isTest
    static void testOnAfterUpdate() {
        List<Task> tasks = [SELECT Id,
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            Priority,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId
            FROM Task LIMIT 1];

        List<Event> events = [SELECT Id, 
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            DurationInMinutes,
            EndDateTime,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            StartDateTime,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId 
            FROM Event LIMIT 1];

        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        for (Task task : tasks) {
            task.Subject = 'Updated ' + task.Subject;
        }
        for (Event event : events) {
            event.Subject = 'Updated ' + event.Subject;
        }

        TAG_ActivityTriggerHelper helperTest = new TAG_ActivityTriggerHelper();

        Test.startTest();
        Update tasks;
        Update events;
        eventEmployerActivityList = helperTest.createEmployerActivityEventForEvent(EVENT_TYPE_DELETED, events[0]);
        taskEmployerActivityList = helperTest.createEmployerActivityEventForTask(EVENT_TYPE_DELETED, tasks[0]);
        Test.stopTest();

        System.assertEquals(1, taskEmployerActivityList.size(), '1 task platform events should have been published.');
        System.assertEquals(1, eventEmployerActivityList.size(), '1 event platform events should have been published.');
    }

    @isTest
    static void testOnAfterUndelete() {
        List<Task> tasks = [SELECT Id,
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            Priority,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId
            FROM Task LIMIT 1];

        List<Event> events = [SELECT Id, 
            TAG_ActivityType__c,
            TAG_AccountNAVUnit__c,
            CRM_AccountOrgNumber__c,
            TAG_AccountOrgType__c,
            TAG_AccountParentId__c,
            TAG_AccountParentOrgNumber__c,
            ActivityDate,
            CreatedDate,
            DurationInMinutes,
            EndDateTime,
            TAG_IACaseNumber__c,
            TAG_IACooperationId__c,
            IASubtheme__c,
            LastModifiedDate,
            RecordTypeId,
            RecordTypeName__c,
            CRM_Region__c,
            RelatedToAccount__c,
            ReminderDateTime,
            TAG_service__c,
            TAG_Status__c,
            StartDateTime,
            Subject,
            TaskEvent__c,
            Type,
            CRM_Unit__c,
            TAG_UserNAVUnit__c,
            WhatId, 
            WhoId 
            FROM Event LIMIT 1];

        List<EmployerActivityEvent__e> taskEmployerActivityList = new List<EmployerActivityEvent__e>();
        List<EmployerActivityEvent__e> eventEmployerActivityList = new List<EmployerActivityEvent__e>();

        TAG_ActivityTriggerHelper helperTest = new TAG_ActivityTriggerHelper();

        Delete tasks;
        Delete events;

        Test.startTest();
        Undelete tasks;
        Undelete events;
        eventEmployerActivityList = helperTest.createEmployerActivityEventForEvent(EVENT_TYPE_DELETED, events[0]);
        taskEmployerActivityList = helperTest.createEmployerActivityEventForTask(EVENT_TYPE_DELETED, tasks[0]);
        Test.stopTest();

        System.assertEquals(1, taskEmployerActivityList.size(), '1 task platform events should have been published.');
        System.assertEquals(1, eventEmployerActivityList.size(), '1 event platform events should have been published.');
    }
}