@isTest
private without sharing class Activity_AddAccountTest {

	@isTest
	private static void testInsertTask() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Task t = createTask( acc );
		t = [SELECT Id, Account__c FROM Task WHERE Id = : t.Id LIMIT 1];

		Test.StartTest();
		Test.StopTest();

		System.assertEquals( acc.Id, t.Account__c, 'Should have added the temp layoffs account to Task.Account__c' );
	}


	@isTest
	private static void testInsertEvent() {


		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event e = createEvent( acc );
		e = [SELECT Id, Account__c FROM Event WHERE Id = : e.Id LIMIT 1];

		Test.StartTest();
		Test.StopTest();

		System.assertEquals( acc.Id, e.Account__c, 'Should have added the temp layoffs account to Event.Account__c' );
	}


	@isTest
	private static void testUpdateTask() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Task t = createTask( acc );
		t = [SELECT Id, Account__c FROM Task WHERE Id = : t.Id LIMIT 1];

		Account newAccount = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, newAccount, true )[0];
		t.WhatId = tl.Id;

		// System.assertEquals( acc.Id, t.Account__c, 'Should have added the temp layoffs account to Task.Account__c' ); // TODO re-enable when inserts work

		Test.StartTest();
		update t;
		Test.StopTest();

		t = [SELECT Id, Account__c FROM Task WHERE Id = : t.Id LIMIT 1];
		System.assertEquals( newAccount.Id, t.Account__c, 'Should have changed to the new temp layoffs account on Task.Account__c' );


	}


	@isTest
	private static void testUpdateEvent() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event e = createEvent( acc );
		e = [SELECT Id, Account__c FROM Event WHERE Id = : e.Id LIMIT 1];

		Account newAccount = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, newAccount, true )[0];
		e.WhatId = tl.Id;

		System.assertEquals( acc.Id, e.Account__c, 'Should have added the temp layoffs account to Event.Account__c' );

		Test.StartTest();
		update e;
		Test.StopTest();

		e = [SELECT Id, Account__c FROM Event WHERE Id = : e.Id LIMIT 1];
		System.assertEquals( newAccount.Id, e.Account__c, 'Should have changed to the new temp layoffs account on Event.Account__c' );

	}


	/* HELPER FUNCTIONS */
	// ------------------------------

	private static Task createTask( Account account ) {

		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, account, true )[0];
		Task ta = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert ta;

		return ta;
	}

	private static Event createEvent( Account account ) {

		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, account, true )[0];
		Event ev = new Event( TAG_NoPersonInformation__c = true, WhatId = tl.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		insert ev;

		return ev;
	}
}