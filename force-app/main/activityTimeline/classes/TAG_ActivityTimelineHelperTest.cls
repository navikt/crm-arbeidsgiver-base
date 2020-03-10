@isTest
private without sharing class TAG_ActivityTimelineHelperTest {

	@isTest
	private static void testCreateSoqlQueries() {

		List<String> mdtFieldsToQuery = new List<String> { 'Activity_Timeline_Child__r.SObjectDateField__c', 'Activity_Timeline_Child__r.SObjectTitle__c' };

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = queryMdt( new List<String> { 'Event', 'Task' } );

		Id recordId = TAG_TestDataFactory.createAccounts( 1 )[0].Id;

		Test.StartTest();
		List<String> queries = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, 3 );
		Test.StopTest();

		System.assertEquals( 3, queries.size(), 'Number of queries should only be 3, as there\'s one query for each unique type + one extra for tasks without dates' );
		System.assert ( queries.size() >= 0, 'Should be some data' );

		for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = TAG_ActivityTimelineHelper.getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
			String expectedEventBeginning = ( 'SELECT Id,ActivityDate,Subject,OwnerId,WhoId,ActivityDateTime,IsAllDayEvent,DurationInMinutes FROM Event WHERE WhatId = \'' + recordId + '\' AND (ActivityDate = LAST_N_MONTHS:2 OR ActivityDate = THIS_MONTH OR ActivityDate > ' + System.today() ).replace( ' 00:00:00', '' );
			String expectedEventEnd = ') ORDER BY ActivityDate';

			String expectedTaskBeginning = ( 'SELECT Id,ActivityDate,Subject,OwnerId,WhoId,Type,Status,CreatedDate FROM Task WHERE WhatId = \'' + recordId + '\' AND (ActivityDate = LAST_N_MONTHS:2 OR ActivityDate = THIS_MONTH OR ActivityDate > ' + System.today() ).replace( ' 00:00:00', '' );
			String expectedTaskEnd = ' ORDER BY ActivityDate';

			for ( String query : queries ) {
				if ( query.contains( 'FROM Event' ) ) {
					System.assert ( query.startsWith( expectedEventBeginning ), 'Expected: ' + expectedEventBeginning + '. Actual: ' + query );
					System.assert ( query.endsWith( expectedEventEnd ), 'Expected: ' + expectedEventEnd + '. Actual: ' + query );
				} else if ( query.contains( 'FROM Task' ) ) {
					if ( query.contains( 'AND ActivityDate = null' ) ) {
						String tmp = expectedTaskBeginning.replaceAll( 'ActivityDate =', 'CreatedDate =' ).replaceAll( 'ActivityDate >', 'CreatedDate >' );
						System.assert ( query.startsWith( tmp ), 'Expected: ' + tmp + '. Actual: ' + query );
						System.assert ( query.endsWith( expectedTaskEnd ), 'Expected: ' + expectedTaskEnd + '. Actual: ' + query );
					} else {
						System.assert ( query.startsWith( expectedTaskBeginning ), 'Expected: ' + expectedTaskBeginning + '. Actual: ' + query );
						System.assert ( query.endsWith( expectedTaskEnd ), 'Expected: ' + expectedTaskEnd + '. Actual: ' + query );
					}
				}
			}
		}
	}

	@isTest
	private static void testGetFieldsToQueryFromMdt_Event() {

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = queryMdt( new List<String> { 'Event' } );

		String expected = 'ActivityDate,Subject,OwnerId,WhoId';

		Test.StartTest();
		String actual = TAG_ActivityTimelineHelper.getFieldsToQueryFromMdt( sObjectsToQuery, sObjectsToQuery[0] );
		Test.StopTest();

		System.assertEquals( expected, actual, 'The fields should be the same' );
	}

	@isTest
	private static void testGetFieldsToQueryFromMdt_Task() {

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = queryMdt( new List<String> { 'Task' } );

		String expected = 'ActivityDate,Subject,OwnerId,WhoId,Type,Status';

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
		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );
		List<String> queries = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, acc.Id, 3 );

		Test.StartTest();
		List<SObject> sObjects = TAG_ActivityTimelineHelper.getSObjectsFromQueries( queries );
		Test.StopTest();

		System.assertEquals( 2, sObjects.size(), 'This account should have one event and one task on it' );
	}

	@isTest
	private static void testGetSObjectsToQuery() {

		Test.StartTest();
		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', false );
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

	@isTest
	private static void testGetRecordTypes() {

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', false );

		Test.StartTest();
		Map<String, Id> recordTypes = TAG_ActivityTimelineHelper.getRecordTypes( sObjectsToQuery );
		Test.StopTest();

		System.assertEquals( 2, recordTypes.size(), 'Currently two mdt objects with record types' );
	}


	// HELPER FUNCTIONS
	// ------------------------------------------------------------------

	public static List<TAG_ActivityTimelineParent__mdt> queryMdt( List<String> types ) {
		return [SELECT Id,

		        SObjectAssigneeId__c, SObjectParent__c, SObjectRelationshipField__c,

		        Activity_Timeline_Child__r.SLDS_Timeline_Color__c, Activity_Timeline_Child__r.SLDS_Icon__c, Activity_Timeline_Child__r.SLDS_Dropdown_Icon__c,
		        Activity_Timeline_Child__r.CreateableObject_TextEnglish__c, Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c, Activity_Timeline_Child__r.CreateableObject_RecordType__c,
		        Activity_Timeline_Child__r.SObjectDateField__c, Activity_Timeline_Child__r.SObjectDateFieldIsDate__c,
		        Activity_Timeline_Child__r.SObjectTypeField__c, Activity_Timeline_Child__r.SObjectTypeValue__c,
		        Activity_Timeline_Child__r.SObjectTitle__c, Activity_Timeline_Child__r.SObjectName__c,
		        Activity_Timeline_Child__r.SObjectRelatedUserId__c,
		        Activity_Timeline_Child__r.CreateableObject_Field1__c, Activity_Timeline_Child__r.CreateableObject_Value1__c,
		        Activity_Timeline_Child__r.CreateableObject_Field2__c, Activity_Timeline_Child__r.CreateableObject_Value2__c,
		        Activity_Timeline_Child__r.CreateableObject_Field3__c, Activity_Timeline_Child__r.CreateableObject_Value3__c,
		        Activity_Timeline_Child__r.SubtitlePastEnglish__c, Activity_Timeline_Child__r.SubtitlePastNorwegian__c,
		        Activity_Timeline_Child__r.SubtitleFutureEnglish__c, Activity_Timeline_Child__r.SubtitleFutureNorwegian__c,
		        Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c, Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c

		        FROM TAG_ActivityTimelineParent__mdt

		        WHERE
		            ( SObjectParent__c = 'Account' ) AND
		            ( Activity_Timeline_Child__r.SObjectName__c IN: types )];
	}
}
