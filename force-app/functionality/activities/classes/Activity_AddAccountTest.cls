@isTest
private without sharing class Activity_AddAccountTest {
  @testSetup
  private static void setup() {
    TAG_TestDataFactory.createUserWithPermset(
      'ARBEIDSGIVER USER',
      new List<String>{
        'Arbeidsgiver_arenaActivity',
        'Arbeidsgiver_base',
        'Arbeidsgiver_contract',
        'Arbeidsgiver_opportunity'
      }
    );
  }

  @isTest
  private static void testInsertTask() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Account acc = TAG_TestDataFactory.createAccounts(1)[0];

      Test.StartTest();
      Task t = createTask(acc);
      Test.StopTest();

      t = [SELECT Id, RelatedToAccount__c FROM Task WHERE Id = :t.Id LIMIT 1];
      System.assertEquals(
        acc.Id,
        t.RelatedToAccount__c,
        'Should have added the temp layoffs account to Task.RelatedToAccount__c'
      );
    }
  }

  @isTest
  private static void testInsertTask_accountAsWhatId() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Account acc = TAG_TestDataFactory.createAccounts(1)[0];
      Task t = new Task(
        TAG_NoPersonInformation__c = true,
        WhatId = acc.Id,
        ActivityDate = Date.today(),
        Subject = 'test'
      );

      Test.StartTest();
      insert t;
      Test.StopTest();

      t = [SELECT Id, RelatedToAccount__c FROM Task WHERE Id = :t.Id LIMIT 1];
      System.assertEquals(
        acc.Id,
        t.RelatedToAccount__c,
        'Should have added the temp layoffs account to Task.RelatedToAccount__c'
      );
    }
  }

  @isTest
  private static void testInsertEvent() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Account acc = TAG_TestDataFactory.createAccounts(1)[0];

      Test.StartTest();
      Event e = createEvent(acc);
      Test.StopTest();

      e = [SELECT Id, RelatedToAccount__c FROM Event WHERE Id = :e.Id LIMIT 1];
      System.assertEquals(
        acc.Id,
        e.RelatedToAccount__c,
        'Should have added the temp layoffs account to Event.RelatedToAccount__c'
      );
    }
  }
/* //This test is depreciated. WhatId is a required field on Task and Event.
  @isTest
  private static void testInsertTask_noWhatId() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Task t = new Task(TAG_NoPersonInformation__c = true, ActivityDate = Date.today(), Subject = 'test');

      Test.StartTest();
      insert t;
      Test.StopTest();

      t = [SELECT Id, RelatedToAccount__c FROM Task WHERE Id = :t.Id LIMIT 1];
      System.assertEquals(
        null,
        t.RelatedToAccount__c,
        'Should NOT have added the account to Event.RelatedToAccount__c'
      );
    }
  }*/

  @isTest
  private static void testUpdateTask() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Account acc = TAG_TestDataFactory.createAccounts(1)[0];
      Task t = createTask(acc);
      t = [SELECT Id, RelatedToAccount__c FROM Task WHERE Id = :t.Id LIMIT 1];

      Account newAccount = TAG_TestDataFactory.createAccounts(1)[0];
      CustomOpportunity__c tl = TAG_TestDataFactory.getCustomOpportunities(1, false)[0];
      tl.Account__c = newAccount.id;
      insert tl;

      t.WhatId = tl.Id;

      System.assertEquals(
        acc.Id,
        t.RelatedToAccount__c,
        'Should have added the temp layoffs account to Task.RelatedToAccount__c'
      );

      Test.StartTest();
      update t;
      Test.StopTest();

      t = [SELECT Id, RelatedToAccount__c FROM Task WHERE Id = :t.Id LIMIT 1];
      System.assertEquals(
        newAccount.Id,
        t.RelatedToAccount__c,
        'Should have changed to the new temp layoffs account on Task.RelatedToAccount__c'
      );
    }
  }

  @isTest
  private static void testUpdateEvent() {
    User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

    System.runAs(u) {
      Account acc = TAG_TestDataFactory.createAccounts(1)[0];
      Event e = createEvent(acc);
      e = [SELECT Id, RelatedToAccount__c FROM Event WHERE Id = :e.Id LIMIT 1];

      Account newAccount = TAG_TestDataFactory.createAccounts(1)[0];
      CustomOpportunity__c tl = TAG_TestDataFactory.getCustomOpportunities(1, false)[0];
      tl.Account__c = newAccount.id;
      insert tl;

      e.WhatId = tl.Id;

      System.assertEquals(
        acc.Id,
        e.RelatedToAccount__c,
        'Should have added the temp layoffs account to Event.RelatedToAccount__c'
      );

      Test.StartTest();
      update e;
      Test.StopTest();

      e = [SELECT Id, RelatedToAccount__c FROM Event WHERE Id = :e.Id LIMIT 1];
      System.assertEquals(
        newAccount.Id,
        e.RelatedToAccount__c,
        'Should have changed to the new temp layoffs account on Event.RelatedToAccount__c'
      );
    }
  }

  /* HELPER FUNCTIONS */
  // ------------------------------

  private static Task createTask(Account account) {
    CustomOpportunity__c tl = TAG_TestDataFactory.getCustomOpportunities(1, false)[0];
    tl.Account__c = account.Id;
    insert tl;
    Id agRecordType = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
      .get('ArbeidsgiverTask')
      .getRecordTypeId();
    Task ta = new Task(
      TAG_NoPersonInformation__c = true,
      WhatId = tl.Id,
      ActivityDate = Date.today(),
      Subject = 'test',
      RecordTypeId = agRecordType
    );
    insert ta;

    return ta;
  }

  private static Event createEvent(Account account) {
    CustomOpportunity__c tl = TAG_TestDataFactory.getCustomOpportunities(1, false)[0];
    tl.Account__c = account.Id;
    insert tl;

    Id agRecordType = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName()
      .get('ArbeidsgiverEvent')
      .getRecordTypeId();

    Event ev = new Event(
      TAG_NoPersonInformation__c = true,
      WhatId = tl.Id,
      DurationInMinutes = 1440,
      IsAllDayEvent = true,
      ActivityDate = Date.today(),
      TAG_ActivityType__c = 'Nedbemanne',
      Subject = 'Hele dagen',
      RecordTypeId = agRecordType
    );
    insert ev;

    return ev;
  }
}
