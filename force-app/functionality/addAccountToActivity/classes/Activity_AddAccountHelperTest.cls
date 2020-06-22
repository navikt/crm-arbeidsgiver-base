@isTest
private without sharing class Activity_AddAccountHelperTest {

	@isTest
	private static void testAddAccount_Task() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Account acc2 = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Task t = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t;
		tl.Account__c = acc2.Id;
		update tl;

		System.assertEquals( null, t.RelatedToAccount__c, 'Null before function' );
		t = [SELECT Id, WhatId, RelatedToAccount__c FROM Task WHERE Id = : t.Id LIMIT 1][0];
		System.assertEquals( acc.Id, t.RelatedToAccount__c, 'old acc after insertion' );

		Test.StartTest();
		t = ( Task ) Activity_AddAccountHelper.addAccount( new List<SObject> { t }, false )[0];
		Test.StopTest();

		System.assertEquals( acc2.Id, t.RelatedToAccount__c, 'Account is added to RelatedToAccount__c' );
	}

	@isTest
	private static void testAddAccount_Event() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Account acc2 = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];
		Event e = new Event( TAG_NoPersonInformation__c = true, WhatId = tl.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen' );
		insert e;
		tl.Account__c = acc2.Id;
		update tl;

		System.assertEquals( null, e.RelatedToAccount__c, 'Null before function' );
		e = [SELECT Id, WhatId, RelatedToAccount__c FROM Event WHERE Id = : e.Id LIMIT 1][0];
		System.assertEquals( acc.Id, e.RelatedToAccount__c, 'old acc after insertion' );

		Test.StartTest();
		e = ( Event ) Activity_AddAccountHelper.addAccount( new List<SObject> { e }, false )[0];
		Test.StopTest();

		System.assertEquals( acc2.Id, e.RelatedToAccount__c, 'Account is added to RelatedToAccount__c' );
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
	private static void testGetWhatIds() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		TemporaryLayoff__c tl = TAG_TestDataFactory.getTemporaryLayoffs( 1, acc, true )[0];

		Task t = new Task( TAG_NoPersonInformation__c = true, WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t;

		Task t2 = new Task( TAG_NoPersonInformation__c = true, WhatId = tl.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert t2;

		Test.StartTest();
		Set<Id> whatIds = Activity_AddAccountHelper.getWhatIds( new List<SObject> { t, t2 } );
		Test.StopTest();

		System.assert (whatIds.contains( acc.Id ), 'Should contain acc id');
		System.assert (whatIds.contains( tl.Id ), 'Should contain tl id');
	}

	@isTest
	private static void testUserHaveAccess_anon() {

		Test.StartTest();
		Boolean result = Activity_AddAccountHelper.userHaveAccess();
		Test.StopTest();

		System.assert (result, 'Anonymous user should always have access');
	}

	@isTest
	private static void testUserHaveAccess_emptyUser() {

		User u = TAG_TestDataFactory.createStandardUser();
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = Activity_AddAccountHelper.userHaveAccess();
		}
		Test.StopTest();

		System.assert (!result, 'Empty user user should NOT have access');
	}

	@isTest
	private static void testUserHaveAccess_emptyUserWithPermset() {

		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Arbeidsgiver_Base_Group' LIMIT 1];
		User u = TAG_TestDataFactory.createStandardUser();
		insert new PermissionSetAssignment( AssigneeId = U.id, PermissionSetId = ps.Id );

		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = Activity_AddAccountHelper.userHaveAccess();
		}
		Test.StopTest();

		System.assert (result, 'New user should have access');
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

		System.assertEquals( null, activities[0].get( 'RelatedToAccount__c' ), 'Should NOT have added the account' );

		Test.StartTest();
		activities = Activity_AddAccountHelper.addAccountToActivity( activities, mapOfActivityAndAccount, false );
		Test.StopTest();

		System.assertEquals( 1, activities.size(), 'Only one activity added' );
		System.assertEquals( account.Id, activities[0].get( 'RelatedToAccount__c' ), 'Should have added the account' );
	}
}
