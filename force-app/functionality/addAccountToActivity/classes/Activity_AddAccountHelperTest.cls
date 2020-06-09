@isTest
private without sharing class Activity_AddAccountHelperTest {

	@isTest
	private static void testAddAccount_Task() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Task t = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t;

		t = [SELECT Id, WhatId, Account__c FROM Task WHERE Id = : t.Id LIMIT 1][0];
		System.assertEquals( null, t.Account__c, 'Null before function' );

		Test.StartTest();
		t = ( Task ) Activity_AddAccountHelper.addAccount( new List<SObject> { t } )[0];
		Test.StopTest();

		System.assertEquals( acc.Id, t.Account__c, 'Account is added to Account__c' );
	}

	@isTest
	private static void testAddAccount_Event() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Event e = new Event( TAG_NoPersonInformation__c = true, WhatId = tl.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		insert e;

		System.assertEquals( null, e.Account__c, 'Null before function' );

		Test.StartTest();
		e = ( Event ) Activity_AddAccountHelper.addAccount( new List<SObject> { e } )[0];
		Test.StopTest();

		System.assertEquals( acc.Id, e.Account__c, 'Account is added to Account__c' );
	}


	@isTest
	private static void testGetActivityWithChangedWhatId_SameWhatId_Event() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Event e_new = new Event( TAG_NoPersonInformation__c = true, WhatId = tl.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		Event e_old = new Event( TAG_NoPersonInformation__c = true, WhatId = tl.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		insert e_new;
		insert e_old;

		Map<Id, SObject> triggerOldMap = new Map<Id, SObject>();
		triggerOldMap.put( e_new.Id, e_old );
		List<SObject> newRecords = new List<SObject> { e_new };

		Test.StartTest();
		List<SObject> results = Activity_AddAccountHelper.getActivityWithChangedWhatId( triggerOldMap, newRecords );
		Test.StopTest();

		System.assertEquals( 0, results.size(), 'Same account on temp layoff, WhatId ' );
	}

	@isTest
	private static void testGetActivityWithChangedWhatId_NewWhatId_Event() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl_new = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		TemporaryLayoff__c tl_old = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Event e_new = new Event( TAG_NoPersonInformation__c = true, WhatId = tl_new.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		Event e_old = new Event( TAG_NoPersonInformation__c = true, WhatId = tl_old.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		insert e_new;
		insert e_old;

		Map<Id, SObject> triggerOldMap = new Map<Id, SObject>();
		triggerOldMap.put( e_new.Id, e_old );
		List<SObject> newRecords = new List<SObject> { e_new };

		Test.StartTest();
		List<SObject> results = Activity_AddAccountHelper.getActivityWithChangedWhatId( triggerOldMap, newRecords );
		Test.StopTest();

		System.assertEquals( 1, results.size(), 'Same account on temp layoff, WhatId ' );
	}


	@isTest
	private static void testGetIdsSeparatedBySObject() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		CustomOpportunity__c opty = TAG_TestDataFactory.getCustomOpportunities( 1, true )[0];

		Test.StartTest();
		Map<String, Set<Id> > result = Activity_AddAccountHelper.getIdsSeparatedBySObject( new Set<Id> { opty.Id, tl.Id } );
		Test.StopTest();

		System.assertEquals( 2, result.size(), 'CustomOpportunity__c and temp layoff should have they\'re own key' );

		System.assert (result.containsKey( 'CustomOpportunity__c' ), 'CustomOpportunity__c should exist as a key');
		System.assertEquals( 1, result.get( 'CustomOpportunity__c' ).size(), 'CustomOpportunity__c should have one ID' );
		System.assertEquals( opty.Id, new List<Id>( result.get( 'CustomOpportunity__c' ) )[0], 'Id should be the same' );

		System.assert (result.containsKey( 'TemporaryLayoff__c' ), 'TemporaryLayoff__c should exist as a key');
		System.assertEquals( 1, result.get( 'TemporaryLayoff__c' ).size(), 'TemporaryLayoff__c should have one ID' );
		System.assertEquals( tl.Id, new List<Id>( result.get( 'TemporaryLayoff__c' ) )[0], 'Id should be the same' );
	}

	@isTest
	private static void testGetSObjectsSeparatedBySObjectType() {


		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		CustomOpportunity__c opty = TAG_TestDataFactory.getCustomOpportunities( 1, true )[0];
		Map<String, Set<Id> > idsSeparatedBySObject = Activity_AddAccountHelper.getIdsSeparatedBySObject( new Set<Id> { opty.Id, tl.Id } );

		Test.StartTest();
		Map<String, List<SObject> > result = Activity_AddAccountHelper.getSObjectsSeparatedBySObjectType( idsSeparatedBySObject );
		Test.StopTest();


		System.assertEquals( 2, result.size(), 'CustomOpportunity__c and temp layoff should have they\'re own key' );

		System.assert (result.containsKey( 'customopportunity__c' ), 'CustomOpportunity__c should exist as a key');
		System.assertEquals( 1, result.get( 'customopportunity__c' ).size(), 'CustomOpportunity__c should have one ID' );
		System.assertEquals( opty.Id, result.get( 'customopportunity__c' )[0].Id, 'Id should be the same' );

		System.assert (result.containsKey( 'temporarylayoff__c' ), 'TemporaryLayoff__c should exist as a key');
		System.assertEquals( 1, result.get( 'temporarylayoff__c' ).size(), 'TemporaryLayoff__c should have one ID' );
		System.assertEquals( tl.Id, result.get( 'temporarylayoff__c' )[0].Id, 'Id should be the same' );
	}

	@isTest
	private static void testGetMapOfActivityAndAccount() {

		Account account = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, account, true )[0];
		Task t = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t;
		List<SObject> activities = new List<SObject> { t };

		Map<String, Set<Id> > idsSeparatedBySObject = Activity_AddAccountHelper.getIdsSeparatedBySObject( new Set<Id> { tl.Id } );
		Map<String, List<SObject> > sObjectsSeparatedBySObject = Activity_AddAccountHelper.getSObjectsSeparatedBySObjectType( idsSeparatedBySObject );

		Test.StartTest();
		Map<Id, Id> mapOfActivityAndAccount = Activity_AddAccountHelper.getMapOfActivityAndAccount( activities, sObjectsSeparatedBySObject );
		Test.StopTest();

		System.assertEquals( 1, mapOfActivityAndAccount.size(), 'Only one activity added' );
		System.assert (mapOfActivityAndAccount.containsKey( t.Id ), 'The task id is the only key');
		System.assertEquals( account.Id, mapOfActivityAndAccount.get( t.Id ), 'The tl id should be the value' );
	}


	@isTest
	private static void testAddAccountToActivity() {

		Account account = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, account, true )[0];
		Task t = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t;
		List<SObject> activities = new List<SObject> { t };

		Map<String, Set<Id> > idsSeparatedBySObject = Activity_AddAccountHelper.getIdsSeparatedBySObject( new Set<Id> { tl.Id } );
		Map<String, List<SObject> > sObjectsSeparatedBySObject = Activity_AddAccountHelper.getSObjectsSeparatedBySObjectType( idsSeparatedBySObject );
		Map<Id, Id> mapOfActivityAndAccount = Activity_AddAccountHelper.getMapOfActivityAndAccount( activities, sObjectsSeparatedBySObject );

		System.assertEquals( null, activities[0].get( 'Account__c' ), 'Should NOT have added the account' );

		Test.StartTest();
		activities = Activity_AddAccountHelper.addAccountToActivity( activities, mapOfActivityAndAccount );
		Test.StopTest();

		System.assertEquals( 1, activities.size(), 'Only one activity added' );
		System.assertEquals( account.Id, activities[0].get( 'Account__c' ), 'Should have added the account' );
	}

}
