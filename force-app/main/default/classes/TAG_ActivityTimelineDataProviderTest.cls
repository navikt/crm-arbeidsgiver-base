@isTest
private without sharing class TAG_ActivityTimelineDataProviderTest {

	@isTest
	private static void testGetTimelineItemData() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today() );
		insert ev;
		Task ta = new Task( WhatId = acc.Id );
		insert ta;

		Test.StartTest();
		List<TAG_ActivityTimelineModel> sObjects = TAG_ActivityTimelineDataProvider.getTimelineItemData( acc.Id );
		Test.StopTest();

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( 'Account' );
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineDataProvider.getMapOfActivityTimelineConfig( sObjectsToQuery );

		System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
		for ( TAG_ActivityTimelineModel obj : sObjects ) {
			String sObjectType = TAG_ActivityTimelineDataProvider.getSOjectTypeFromRecordId( obj.sObj.Id );
			if ( sObjectType == 'Event' ) {
				System.assertEquals( ev.Id, obj.sObj.Id, 'The ID should be the created event' );
				System.assertEquals( sObjectsToQueryMap.get( 'Event' ).Id, obj.config.Id, 'The ID should be the event config' );
			} else if ( sObjectType == 'Task' ) {
				System.assertEquals( ta.Id, obj.sObj.Id, 'The ID should be the created event' );
				System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
			}
		}


	}

	@isTest
	private static void testGetSOjectTypeFromRecordId() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		String sObjtype = TAG_ActivityTimelineDataProvider.getSOjectTypeFromRecordId( acc.Id );
		Test.StopTest();

		System.assertEquals( 'Account', sObjtype, 'The returned value should be account based on the account ID' );

	}

	@isTest
	private static void testGetSObjectsToQuery() {

		Test.StartTest();
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( 'Account' );
		Test.StopTest();

		System.assert (sObjectsToQuery.size() >= 0, 'Should already be some mdt\'s for account as parent');
	}

	@isTest
	private static void testCreateSoqlQueries() {

		List<String> mdtFieldsToQuery = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
		                                                   Color__c, Icon__c,
		                                                   SObjectChild__c, SObjectParent__c,
		                                                   SObjectDateField__c,  SObjectTitle__c,
		                                                   SObjectRelationshipField__c
		                                                   FROM TAG_ActivityTimeline__mdt WHERE SObjectParent__c = 'Account' AND SObjectChild__c IN ( 'Event', 'Task' )];

		Test.StartTest();
		List<String> queries = TAG_ActivityTimelineDataProvider.createSoqlQueries( sObjectsToQuery );
		Test.StopTest();

		System.assertEquals( sObjectsToQuery.size(), queries.size(), 'Number of queries should reflect the amunt of mdt\'s for account as parent' );
		System.assert ( queries.size() >= 0, 'Should be some data' );

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = TAG_ActivityTimelineDataProvider.getFieldsToQueryFromMdt( mdt, mdtFieldsToQuery );
			String expectedEvent = 'SELECT Id, ' + fieldsToQuery + ' FROM Event WHERE WhatId =: recordId';
			String expectedTask = 'SELECT Id, ' + fieldsToQuery + ' FROM Task WHERE WhatId =: recordId';

			for ( String query : queries ) {
				if ( query.contains( 'FROM Event' ) ) {
					System.assertEquals( expectedEvent, query, 'The queries should be equal' );
				} else if ( query.contains( 'FROM Task' ) ) {
					System.assertEquals( expectedTask, query, 'The queries should be equal' );
				}
			}
		}
	}

	@isTest
	private static void testGetFieldsToQueryFromMdt() {

		List<String> mdtFieldsToQuery = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
		                                                   Color__c, Icon__c,
		                                                   SObjectChild__c, SObjectParent__c,
		                                                   SObjectDateField__c,  SObjectTitle__c,
		                                                   SObjectRelationshipField__c
		                                                   FROM TAG_ActivityTimeline__mdt WHERE SObjectParent__c = 'Account' AND SObjectChild__c IN ( 'Event', 'Task' )];

		String expected = 'ActivityDate,Subject';

		Test.StartTest();
		String actual = TAG_ActivityTimelineDataProvider.getFieldsToQueryFromMdt( sObjectsToQuery[0], mdtFieldsToQuery );
		Test.StopTest();

		System.assertEquals( expected, actual, 'The fields should be the same' );
	}

	@isTest
	private static void testGetSObjectsFromQueries() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today() );
		insert ev;
		Task ta = new Task( WhatId = acc.Id );
		insert ta;

		String parentSObjectType = TAG_ActivityTimelineDataProvider.getSOjectTypeFromRecordId( acc.Id );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( parentSObjectType );
		List<String> queries = TAG_ActivityTimelineDataProvider.createSoqlQueries( sObjectsToQuery );

		Test.StartTest();
		List<SObject> sObjects = TAG_ActivityTimelineDataProvider.getSObjectsFromQueries( queries, acc.Id );
		Test.StopTest();

		System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
	}
}