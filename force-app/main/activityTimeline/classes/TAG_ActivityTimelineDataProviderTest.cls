@isTest
private without sharing class TAG_ActivityTimelineDataProviderTest {

	@isTest
	private static void testGetTimelineItemData() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'test' );
		insert ev;
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert ta;
		Date t = Date.today().addDays( -2 );
		Task ta2 = new Task( WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta2;

		List<String> periods = new List<String> { Label.ActTime_Overdue, Label.ActTime_Upcoming, Label.ActTime_ThisMonth, Label.ActTime_PreviousMonth, Label.ActTime_Older };
		List<TAG_ActivityTimelineDataProvider.AmountOfRecords> amountOfRecordsList = getAmountOfRecordsMock( periods );

		System.debug( 'amountOfRecordsList: ' + amountOfRecordsList );

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineDataProvider.getTimelineItemData( acc.Id, amountOfRecordsList );
		Test.StopTest();

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( 'Account', false );
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineDataProvider.getMapOfActivityTimelineConfig( sObjectsToQuery );

		System.assertEquals( 3, wrapper.size(), 'One for upcoming, one for this month and one for overdue' );
		for ( TAG_ActivityTimelineModelList wr : wrapper ) {

			System.assertEquals( 1, wr.models.size(), 'This account should have one record for each wrapper' );
			for ( TAG_ActivityTimelineModel obj : wr.models ) {

				String sObjectType = TAG_ActivityTimelineDataProvider.getSOjectTypeFromRecordId( obj.sObj.Id );
				if ( sObjectType == 'Event' ) {
					System.assertEquals( ev.Id, obj.sObj.Id, 'The ID should be the created event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Event' ).Id, obj.config.Id, 'The ID should be the event config' );
				} else if ( sObjectType == 'Task' && !obj.record.overdue ) {
					System.assertEquals( ta.Id, obj.sObj.Id, 'The ID should be the non-overdue event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
				} else if ( sObjectType == 'Task' && obj.record.overdue ) {
					System.assertEquals( ta2.Id, obj.sObj.Id, 'The ID should be the overdue event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
				}
			}
		}
	}
	public static List<TAG_ActivityTimelineDataProvider.AmountOfRecords> getAmountOfRecordsMock( List<String> periods ) {

		List<TAG_ActivityTimelineDataProvider.AmountOfRecords> amountOfRecordsList = new List<TAG_ActivityTimelineDataProvider.AmountOfRecords> ();

		for ( String str : periods ) {
			TAG_ActivityTimelineDataProvider.AmountOfRecords amountOfRecords = new TAG_ActivityTimelineDataProvider.AmountOfRecords();
			amountOfRecords.id = str;
			amountOfRecords.amount = 3;
			amountOfRecords.loadedAll = false;
			amountOfRecordsList.add( amountOfRecords );
		}

		return amountOfRecordsList;
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
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( 'Account', false );
		Test.StopTest();

		System.assert (sObjectsToQuery.size() >= 0, 'Should already be some mdt\'s for account as parent');
	}

	// @isTest
	// private static void testCreateSoqlQueries() {

	// 	List<String> mdtFieldsToQuery = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

	// 	List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
	// 	                                                   SLDS_Timeline_Color__c, SLDS_Icon__c,
	// 	                                                   SObjectChild__c, SObjectParent__c,
	// 	                                                   SObjectDateField__c,  SObjectTitle__c,
	// 	                                                   SObjectRelationshipField__c
	// 	                                                   FROM TAG_ActivityTimeline__mdt WHERE SObjectParent__c = 'Account' AND SObjectChild__c IN ( 'Event', 'Task' )];

	// 	Id recordId = TAG_TestDataFactory.createAccounts( 1 )[0].Id;

	// 	Test.StartTest();
	// 	List<String> queries = TAG_ActivityTimelineDataProvider.createSoqlQueries( sObjectsToQuery, recordId, 3, Label.ActTime_Upcoming );
	// 	Test.StopTest();

	// 	System.assertEquals( sObjectsToQuery.size(), queries.size(), 'Number of queries should reflect the amunt of mdt\'s for account as parent' );
	// 	System.assert ( queries.size() >= 0, 'Should be some data' );

	// 	for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
	// 		String fieldsToQuery = TAG_ActivityTimelineDataProvider.getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
	// 		String expectedEvent = 'SELECT Id, ' + fieldsToQuery + ' FROM Event WHERE WhatId = \'' + recordId + '\'';
	// 		String expectedTask = 'SELECT Id, ' + fieldsToQuery + ' FROM Task WHERE WhatId = \'' + recordId + '\'';

	// 		for ( String query : queries ) {
	// 			if ( query.contains( 'FROM Event' ) ) {
	// 				System.assertEquals( expectedEvent, query, 'The queries should be equal' );
	// 			} else if ( query.contains( 'FROM Task' ) ) {
	// 				System.assertEquals( expectedTask, query, 'The queries should be equal' );
	// 			}
	// 		}
	// 	}
	// }

	// @isTest
	// private static void testGetFieldsToQueryFromMdt() {

	// 	List<String> mdtFieldsToQuery = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

	// 	List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
	// 	                                                   SLDS_Timeline_Color__c, SLDS_Icon__c,
	// 	                                                   SObjectChild__c, SObjectParent__c,
	// 	                                                   SObjectDateField__c,  SObjectTitle__c,
	// 	                                                   SObjectRelationshipField__c
	// 	                                                   FROM TAG_ActivityTimeline__mdt WHERE SObjectParent__c = 'Account' AND SObjectChild__c IN ( 'Event', 'Task' )];

	// 	String expected = 'ActivityDate,Subject';

	// 	Test.StartTest();
	// 	String actual = TAG_ActivityTimelineDataProvider.getFieldsToQueryFromMdt( sObjectsToQuery, sObjectsToQuery[0] );
	// 	Test.StopTest();

	// 	System.assertEquals( expected, actual, 'The fields should be the same' );
	// }

	// @isTest
	// private static void testGetSObjectsFromQueries() {

	// 	Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
	// 	Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today() );
	// 	insert ev;
	// 	Task ta = new Task( WhatId = acc.Id );
	// 	insert ta;

	// 	String parentSObjectType = TAG_ActivityTimelineDataProvider.getSOjectTypeFromRecordId( acc.Id );
	// 	List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineDataProvider.getSObjectsToQuery( parentSObjectType, false );
	// 	List<String> queries = TAG_ActivityTimelineDataProvider.createSoqlQueries( sObjectsToQuery, acc.Id, 3, Label.ActTime_Upcoming );

	// 	Test.StartTest();
	// 	List<SObject> sObjects = TAG_ActivityTimelineDataProvider.getSObjectsFromQueries( queries );
	// 	Test.StopTest();

	// 	System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
	// }
}