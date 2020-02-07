public with sharing class TAG_ActivityTimelineController {

	private static final User USER =                [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =     USER.LanguageLocaleKey == 'Norsk';

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getTimelineItemData( String recordId, Integer amountOfMonths ) {

		System.debug( '------------------------------\n getTimelineItemData\n------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                          TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery =   TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );

		List<TAG_ActivityTimelineModelList> results =       new List<TAG_ActivityTimelineModelList>();

		List<String>                    query =             TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, amountOfMonths );
		List<SObject>                   sObjects =          TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data =              TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );
		data.sort();

		List<TAG_ActivityTimelineModel> upcoming =          TAG_ActivityTimelineHelper.getUpcomingOnly( data );
		TAG_ActivityTimelineModelList wrappedUpcoming =     new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcoming, false, false );
		List<TAG_ActivityTimelineModelList> wrappedMonths = TAG_ActivityTimelineHelper.getRecordsDividedIntoMonths( data );

		results.add( wrappedUpcoming );
		results.addAll( wrappedMonths );

		return results;
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getOverdueTasks( String recordId ) {

		System.debug( '------------------------------\n getOverdueTasks\n------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                          TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery =   TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );

		List<TAG_ActivityTimelineModelList> data =          new List<TAG_ActivityTimelineModelList>();
		List<TAG_ActivityTimelineModel> overdue =           TAG_ActivityTimelineHelper.getOverdueOnly( sObjectsToQuery, recordId );
		TAG_ActivityTimelineModelList overdueWrapper =      new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, overdue, false, true );
		data.add( overdueWrapper );

		return data;
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {

		System.debug( '------------------------------\n getTimelineObjects\n------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                          TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data =              TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes =                       TAG_ActivityTimelineHelper.getRecordTypes( data );

		if ( IS_NORWEGIAN ) {
			for ( TAG_ActivityTimeline__mdt mdt : data ) {
				mdt.CreateableObject_TextEnglish__c = mdt.CreateableObject_TextNorwegian__c;
			}
		}

		for ( TAG_ActivityTimeline__mdt mdt : data ) {
			mdt.CreateableObject_RecordType__c = recordTypes.get( mdt.SObjectChild__c + mdt.CreateableObject_RecordType__c );
		}

		return data;
	}
}