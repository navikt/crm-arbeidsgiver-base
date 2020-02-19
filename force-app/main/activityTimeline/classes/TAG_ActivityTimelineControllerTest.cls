@isTest
private without sharing class TAG_ActivityTimelineControllerTest {

	@isTest
	private static void testGetActivityTimelineData_UpcomingTask() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Contact con = new Contact( LastName = 'Test' );
		insert con;

		Date d = Date.today();
		Task ta = new Task( WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id );
		insert ta;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();

		System.assertEquals( 1, wrapper.size(), 'one for upcoming' );
		System.assertEquals( 1, wrapper[0].models.size(), 'contains one in upcoming' );
		System.assertEquals( Label.ActTime_Upcoming, wrapper[0].id, 'upcoming label as id' );
		System.assertEquals( ta.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created task' );
	}

	@isTest
	private static void testGetActivityTimelineData_UpcomingAllDayEvent() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Contact con = new Contact( LastName = 'Test' );
		insert con;

		Date d = Date.today();
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1440, IsAllDayEvent = true, ActivityDate = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'Hele dagen', WhoId = con.Id );
		insert ev;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();

		System.assertEquals( 1, wrapper.size(), 'One for upcoming' );
		System.assertEquals( 1, wrapper[0].models.size(), 'contains one in upcoming' );
		System.assertEquals( Label.ActTime_Upcoming, wrapper[0].id, 'upcoming label as id' );
		System.assertEquals( ev.Id, wrapper[0].models[0].record.recordId, 'The ID should be the created event' );
	}

	@isTest
	private static void testGetActivityTimelineData_HistoricTask() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Contact con = new Contact( LastName = 'Test' );
		insert con;

		Date d = Date.today().addDays( -2 );
		Task ta = new Task( WhatId = acc.Id, ActivityDate = d, Subject = 'test', WhoId = con.Id );
		insert ta;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();
		System.assertEquals( 2, wrapper.size(), 'One for this month and one for upcoming, which is empty' );

		System.assertEquals( 0, wrapper[0].models.size(), 'Empty upcoming' );
		System.assertEquals( 1, wrapper[1].models.size(), 'One record in month view' );

		System.assertEquals( Label.ActTime_Upcoming, wrapper[0].id, 'upcoming label as id' );
		System.assertEquals( d.month() + '' + d.year(), wrapper[1].id, 'month-year format as id' );

		System.assertEquals( ta.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event' );
	}

	@isTest
	private static void testGetActivityTimelineData_HistoricEvent() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Contact con = new Contact( LastName = 'Test' );
		insert con;

		Date d = Date.today().addDays( -1 );
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = d, TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'i går', WhoId = con.Id );
		insert ev;

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5, '' );
		Test.StopTest();

		System.assertEquals( 2, wrapper.size(), 'One for this month and one for upcoming, which is empty' );

		System.assertEquals( 0, wrapper[0].models.size(), 'Empty upcoming' );
		System.assertEquals( 1, wrapper[1].models.size(), 'One record in month view' );

		System.assertEquals( Label.ActTime_Upcoming, wrapper[0].id, 'upcoming label as id' );
		System.assertEquals( d.month() + '' + d.year(), wrapper[1].id, 'month-year format as id' );

		System.assertEquals( ev.Id, wrapper[1].models[0].record.recordId, 'The ID should be the created event' );
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
				System.assertEquals( mdt.Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c, mdt.Activity_Timeline_Child__r.CreateableObject_TextEnglish__c, 'The norwegian text should be moved to the english field, as this user is norwegian' );
			}
		}
	}
}