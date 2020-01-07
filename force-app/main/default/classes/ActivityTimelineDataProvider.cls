public with sharing class ActivityTimelineDataProvider {
	@AuraEnabled(cacheable = false)
	public static List<SObject> getTimelineItemData( String recordId ) {
		System.debug( 'wvrefr' );

		return [SELECT Id, OwnerId, IsAllDayEvent, ActivityDate, EndDatetime, EventSubtype, Location, WhoId, WhatId, Subject FROM Event WHERE WhatId = : recordId];
	}
}
