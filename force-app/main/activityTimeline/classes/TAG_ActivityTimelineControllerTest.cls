@isTest
private without sharing class TAG_ActivityTimelineControllerTest {

	@isTest

	private static void testGetActivityTimelineData() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Event ev = new Event( WhatId = acc.Id, DurationInMinutes = 1, ActivityDateTime = Date.today(), TAG_ActivityType__c = 'Bedriftsundersøkelse', Subject = 'test' );
		insert ev;
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test' );
		insert ta;
		Date t = Date.today().addDays( -2 );
		Task ta2 = new Task( WhatId = acc.Id, ActivityDate = t, Subject = 'test' );
		insert ta2;

		List<String> periods = new List<String> { Label.ActTime_Overdue, Label.ActTime_Upcoming, Label.ActTime_ThisMonth, Label.ActTime_PreviousMonth, Label.ActTime_Older };

		Test.StartTest();
		List<TAG_ActivityTimelineModelList> wrapper = TAG_ActivityTimelineController.getActivityTimelineData( acc.Id, 5 );
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
}