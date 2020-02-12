@isTest
private without sharing class TAG_ActivityTimelineControllerTest {

	@isTest
	private static void testGetActivityTimelineData() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Contact con = new Contact( LastName = 'Test' );
		insert con;

		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'test', WhoId = con.Id );
		insert ev;
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test', WhoId = con.Id );
		insert ta;
		Date t = Date.today().addDays( -2 );
		Task ta2 = new Task( WhatId = acc.Id, ActivityDate = t, Subject = 'test', WhoId = con.Id );
		insert ta2;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', false );
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineHelper.getMapOfActivityTimelineConfig( sObjectsToQuery );

		System.assertEquals( 2, wrapper.size(), 'One for upcoming and one for this month ' );
		for ( TAG_ActivityTimelineModelList wr : wrapper ) {

			if ( wr.id == Label.ActTime_Upcoming ) {
				System.assertEquals( 1, wr.models.size(), 'This account should have one record for each wrapper' );
			} else {
				System.assertEquals( 2, wr.models.size(), 'This account should have two records for the month wrapper, because overdue records are still counted' );
			}

			for ( TAG_ActivityTimelineModel obj : wr.models ) {

				String sObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( obj.record.recordId );
				if ( sObjectType == 'Event' ) {
					System.assertEquals( ev.Id, obj.record.recordId, 'The ID should be the created event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Event' ).Id, obj.config.Id, 'The ID should be the event config' );
				} else if ( sObjectType == 'Task' && !obj.record.overdue ) {
					System.assertEquals( ta.Id, obj.record.recordId, 'The ID should be the non-overdue event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
				} else if ( sObjectType == 'Task' && obj.record.overdue ) {
					System.assertEquals( ta2.Id, obj.record.recordId, 'The ID should be the overdue event' );
					System.assertEquals( sObjectsToQueryMap.get( 'Task' ).Id, obj.config.Id, 'The ID should be the task config' );
				}
			}
		}
	}


	@isTest
	private static void testGetActivityTimelineData_customOpportunity() {

		Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Inclusive_Employment'].Id;

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		CustomOpportunity__c co = new CustomOpportunity__c( InquiryCategory__c = 'Rekruttering', Municipality__c = 'Ski', InclusionStage__c = 'Ny henvendelse', RecordTypeId = recordTypeId, Account__c = acc.Id );
		insert co;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', false );
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineHelper.getMapOfActivityTimelineConfig( sObjectsToQuery );
		System.debug( 'sObjectsToQueryMap: ' + sObjectsToQueryMap );
		System.assertEquals( 2, wrapper.size(), 'One for upcoming (empty) and this month ' );

		TAG_ActivityTimelineModelList wr = wrapper[1];
		System.assertEquals( System.today().month() + '' + System.today().year(), wr.Id, 'The id for the current month is month number + year' );

		for ( TAG_ActivityTimelineModel obj : wr.models ) {
			System.assertEquals( co.Id, obj.record.recordId, 'The ID should be the created opty' );
			System.assertEquals( sObjectsToQueryMap.get( 'CustomOpportunity__cRekruttering' ).Id, obj.config.Id, 'The ID should be the Custom opty with Inclusive_Employment record type config' );
		}
	}

	@isTest
	private static void testGetOverdueTasks() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'test' );
		insert ev;
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert ta;
		Date t = Date.today().addDays( -2 );
		Task ta2 = new Task( WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta2;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> data = TAG_ActivityTimelineController.getOverdueTasks( acc.Id );
		Test.StopTest();

		System.assertEquals( 1, data.size(), 'Only one wrapper, as it only contains overdue tasks' );
		System.assertEquals( 1, data[0].models.size(), 'Only one records, as only one task created is overdue and events cannot be overdue (no completion or status)' );

	}

	@isTest
	private static void testGetTimelineObjects() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		List<TAG_ActivityTimeline__mdt> sObjectType = TAG_ActivityTimelineController.getTimelineObjects( acc.Id );
		Test.StopTest();

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', true );

		System.assertEquals( sObjectsToQuery.size(), sObjectType.size(), 'Should be the same size of MDT objects' );
	}

	@isTest
	private static void testGetTimelineObjects_noAccessAndChangedLanguage() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		User u = TAG_TestDataFactory.createStandardUser();

		System.runAs( u )
		{
			Test.StartTest();
			List<TAG_ActivityTimeline__mdt> sObjectType = TAG_ActivityTimelineController.getTimelineObjects( acc.Id );
			Test.StopTest();

			System.assertEquals( 4, sObjectType.size(), 'Standard user doesn\'t have access to custom object custom opportunity' );

			for ( TAG_ActivityTimeline__mdt mdt : sObjectType ) {
				System.assertEquals( mdt.CreateableObject_TextNorwegian__c, mdt.CreateableObject_TextEnglish__c, 'The norwegian text should be moved to the english field, as this user is norwegian' );
			}
		}
	}
}