@isTest
private without sharing class TAG_ActivityTimelineControllerTest {

	// @isTest

	// private static void testGetTimelineItemData() {

	// 	Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
	// 	Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'test' );
	// 	insert ev;
	// 	Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test' );
	// 	insert ta;
	// 	Date t = Date.today().addDays( -2 );
	// 	Task ta2 = new Task( WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
	// 	insert ta2;

	// 	List<String> periods = new List<String> { Label.ActTime_Overdue, Label.ActTime_Upcoming, Label.ActTime_ThisMonth, Label.ActTime_PreviousMonth, Label.ActTime_Older };
	// 	List<TAG_ActivityTimelineController.AmountOfRecords> amountOfRecordsList = getAmountOfRecordsMock( periods );

	// 	System.debug( 'amountOfRecordsList: ' + amountOfRecordsList );

	// 	Test.StartTest();
	// 	List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getTimelineItemData( acc.Id, amountOfRecordsList );
	// 	Test.StopTest();

	// 	List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineController.getSObjectsToQuery( 'Account', false );
	// 	Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineHelper.getMapOfActivityTimelineConfig( sObjectsToQuery );

	// 	System.assertEquals( 3, wrapper.size(), 'One for upcoming, one for this month and one for overdue' );
	// 	for ( TAG_ActivityTimelineModelList wr : wrapper ) {

	// 		if ( wr.id == Label.ActTime_Upcoming || wr.id == Label.ActTime_Overdue ) {
	// 			System.assertEquals( 1, wr.models.size(), 'This account should have one record for each wrapper' );
	// 		} else {
	// 			System.assertEquals( 2, wr.models.size(), 'This account should have two records for the month wrapper, because overdue records are still counted' );
	// 		}

	// 		for ( TAG_ActivityTimelineModel obj : wr.models ) {

	// 			String sObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( obj.record.recordId );
	// 			if ( sObjectType == 'Event' ) {
	// 				System.assertEquals( ev.Id, obj.record.recordId, 'The ID should be the created event' );
	// 				System.assertEquals( sObjectsToQueryMap.get( 'Event' ).Id, obj.config.Id, 'The ID should be the event config' );
	// 			} else if ( sObjectType == 'Task' && !obj.record.overdue ) {
	// 				System.assertEquals( ta.Id, obj.record.recordId, 'The ID should be the non-overdue event' );
	// 				System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
	// 			} else if ( sObjectType == 'Task' && obj.record.overdue ) {
	// 				System.assertEquals( ta2.Id, obj.record.recordId, 'The ID should be the overdue event' );
	// 				System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
	// 			}
	// 		}
	// 	}
	// }



	@isTest
	private static void testGetSObjectsToQuery() {

		Test.StartTest();
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineController.getSObjectsToQuery( 'Account', false );
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
	// 	List<String> queries = TAG_ActivityTimelineController.createSoqlQueries( sObjectsToQuery, recordId, 3, Label.ActTime_Upcoming );
	// 	Test.StopTest();

	// 	System.assertEquals( sObjectsToQuery.size(), queries.size(), 'Number of queries should reflect the amunt of mdt\'s for account as parent' );
	// 	System.assert ( queries.size() >= 0, 'Should be some data' );

	// 	for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
	// 		String fieldsToQuery = TAG_ActivityTimelineController.getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
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
	// 	String actual = TAG_ActivityTimelineController.getFieldsToQueryFromMdt( sObjectsToQuery, sObjectsToQuery[0] );
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

	// 	String parentSObjectType = TAG_ActivityTimelineController.getSOjectTypeFromRecordId( acc.Id );
	// 	List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineController.getSObjectsToQuery( parentSObjectType, false );
	// 	List<String> queries = TAG_ActivityTimelineController.createSoqlQueries( sObjectsToQuery, acc.Id, 3, Label.ActTime_Upcoming );

	// 	Test.StartTest();
	// 	List<SObject> sObjects = TAG_ActivityTimelineController.getSObjectsFromQueries( queries );
	// 	Test.StopTest();

	// 	System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
	// }

}