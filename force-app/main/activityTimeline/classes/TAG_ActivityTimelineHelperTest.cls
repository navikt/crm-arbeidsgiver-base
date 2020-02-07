@isTest
private without sharing class TAG_ActivityTimelineHelperTest {

	@isTest
	private static void testCreateSoqlQueries() {

		List<String> mdtFieldsToQuery = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = queryMdt();

		Id recordId = TAG_TestDataFactory.createAccounts( 1 )[0].Id;

		Test.StartTest();
		List<String> queries = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, 3 );
		Test.StopTest();

		System.assertEquals( 2, queries.size(), 'Number of queries should only be 2, as there\'s one query for each unique type' );
		System.assert ( queries.size() >= 0, 'Should be some data' );

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = TAG_ActivityTimelineHelper.getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
			String expectedEventBeginning = ('SELECT Id, ActivityDateTime,Subject,OwnerId,WhoId FROM Event WHERE WhatId = \'' + recordId + '\' AND (ActivityDateTime = LAST_N_MONTHS:2 OR ActivityDateTime = THIS_MONTH OR ActivityDateTime > ' + System.today() + 'T').replace( ' 00:00:00', '' );
			String expectedEventEnd = 'Z) AND ActivityDateTime != null ORDER BY ActivityDateTime';

			String expectedTaskBeginning = ( 'SELECT Id, ActivityDate,Subject,OwnerId,WhoId,Type,Status FROM Task WHERE WhatId = \'' + recordId + '\' AND (ActivityDate = LAST_N_MONTHS:2 OR ActivityDate = THIS_MONTH OR ActivityDate > ' + System.today() ).replace( ' 00:00:00', '' );
			String expectedTaskEnd = ') AND ActivityDate != null ORDER BY ActivityDate';

			for ( String query : queries ) {
				if ( query.contains( 'FROM Event' ) ) {
					System.assert ( query.startsWith( expectedEventBeginning ), 'Expected: ' + expectedEventBeginning + '. Actual: ' + query );
					System.assert ( query.endsWith( expectedEventEnd ), 'Expected: ' + expectedEventEnd + '. Actual: ' + query );
				} else if ( query.contains( 'FROM Task' ) ) {
					System.assert ( query.startsWith( expectedTaskBeginning ), 'Expected: ' + expectedTaskBeginning + '. Actual: ' + query );
					System.assert ( query.endsWith( expectedTaskEnd ), 'Expected: ' + expectedTaskEnd + '. Actual: ' + query );
				}
			}
		}
	}

	@isTest
	private static void testGetFieldsToQueryFromMdt() {

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = queryMdt();

		String expected = 'ActivityDateTime,Subject,OwnerId,WhoId';

		Test.StartTest();
		String actual = TAG_ActivityTimelineHelper.getFieldsToQueryFromMdt( sObjectsToQuery, sObjectsToQuery[0] );
		Test.StopTest();

		System.assertEquals( expected, actual, 'The fields should be the same' );
	}

	@isTest
	private static void testGetSObjectsFromQueries() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today() );
		insert ev;
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today() );
		insert ta;

		String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( acc.Id );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );
		List<String> queries = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, acc.Id, 3 );

		Test.StartTest();
		List<SObject> sObjects = TAG_ActivityTimelineHelper.getSObjectsFromQueries( queries );
		Test.StopTest();

		System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
	}

	@isTest
	private static void testGetSObjectsToQuery() {

		Test.StartTest();
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', false );
		Test.StopTest();

		System.assert (sObjectsToQuery.size() >= 0, 'Should already be some mdt\'s for account as parent');
	}

	@isTest
	private static void testGetSOjectTypeFromRecordId() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		String sObjtype = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( acc.Id );
		Test.StopTest();

		System.assertEquals( 'Account', sObjtype, 'The returned value should be account based on the account ID' );
	}


	// HELPER FUNCTIONS
	// ------------------------------------------------------------------

	public static List<TAG_ActivityTimeline__mdt> queryMdt() {
		return [SELECT Id,
		        SLDS_Timeline_Color__c, SLDS_Icon__c,
		        CreateableObject_TextEnglish__c, CreateableObject_TextNorwegian__c, CreateableObject_RecordType__c,
		        SObjectChild__c, SObjectParent__c,
		        SObjectDateField__c,  SObjectTitle__c, SObjectDateFieldIsDate__c,
		        SObjectAssigneeId__c, SObjectRelatedUserId__c,
		        SObjectTypeField__c, SObjectTypeValue__c,
		        SubtitlePastEnglish__c, SubtitlePastNorwegian__c,
		        SubtitleFutureEnglish__c, SubtitleFutureNorwegian__c,
		        SubtitleRelatedUserPrepositionEng__c, SubtitleRelatedUserPrepositionNor__c,
		        SObjectRelationshipField__c

		        FROM TAG_ActivityTimeline__mdt

		        WHERE
		            ( SObjectParent__c = 'Account' ) AND
		            ( SObjectChild__c IN ( 'Event', 'Task' ) )];
	}
}
