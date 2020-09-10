@isTest
private class TAG_ActivityTimelineModelTest {

	@isTest
	private static void testSorting_history() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Date t = Date.today().addMonths( -5 );
		Task ta = new Task( TAG_NoPersonInformation__c = true, WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta;

		t = t.addMonths( -1 );
		Event ev = new Event( TAG_NoPersonInformation__c = true, WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, TAG_ActivityType__c = 'Nedbemanne', Subject = 'test' );
		insert ev;

		t = t.addMonths( -1 );
		Task ta2 = new Task( TAG_NoPersonInformation__c = true, WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta2;

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', true );
		List<String> query = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, acc.Id, 8 );
		List<SObject> sObjects = TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data = TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );

		System.assertEquals( 3, data.size(), 'Three records added to account' );

		data = new TAG_ActivityTimelineModelList( Label.ActTime_Older, Label.ActTime_Older, data, false, true ).models;

		System.assertEquals( ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list' );
		System.assertEquals( ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list' );
		System.assertEquals( ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list' );
	}

	@isTest
	private static void testSorting_future() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Date t = Date.today().addDays( 1 );
		Task ta = new Task( TAG_NoPersonInformation__c = true, WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta;

		t = t.addDays( 1 );
		Event ev = new Event( TAG_NoPersonInformation__c = true, WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = t, TAG_ActivityType__c = 'Nedbemanne', Subject = 'test' );
		insert ev;

		t = t.addDays( 1 );
		Task ta2 = new Task( TAG_NoPersonInformation__c = true, WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta2;

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( 'Account', true );
		List<String> query = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, acc.Id, 5 );
		List<SObject> sObjects = TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data = TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );

		System.assertEquals( 3, data.size(), 'Three records added to account' );

		data = new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, data, false, false ).models;

		System.assertEquals( ta.Id, data[0].record.recordId, 'The ID for the task should be in 1st in the list' );
		System.assertEquals( ev.Id, data[1].record.recordId, 'The ID for the event should be in 2nd in the list' );
		System.assertEquals( ta2.Id, data[2].record.recordId, 'The ID for the task should be in 3rd in the list' );
	}
}