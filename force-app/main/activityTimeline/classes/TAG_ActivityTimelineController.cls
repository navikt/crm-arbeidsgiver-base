public with sharing class TAG_ActivityTimelineController {

	private static final User USER =                [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =     USER.LanguageLocaleKey == 'Norsk';

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getActivityTimelineData( String recordId, Integer amountOfMonths, String timestamp ) {

		System.debug( '\n------------------------------------------\n------------getActivityTimelineData------------\n------------------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                              TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );

		List<TAG_ActivityTimelineModelList> results =           new List<TAG_ActivityTimelineModelList>();

		List<String>                    query =                 TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, amountOfMonths );
		List<SObject>                   sObjects =              TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data =                  TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );
		data =                                                  TAG_ActivityTimelineHelper.getOwnerAndContactNames( data );
		data.sort();

		List<TAG_ActivityTimelineModel> upcoming =              TAG_ActivityTimelineHelper.getUpcomingOnly( data );
		TAG_ActivityTimelineModelList wrappedUpcoming =         new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcoming, false, false );
		List<TAG_ActivityTimelineModelList> wrappedMonths =     TAG_ActivityTimelineHelper.getRecordsDividedIntoMonths( data );

		results.add( wrappedUpcoming );
		results.addAll( wrappedMonths );

		results = TAG_ActivityTimelineHelper.removeConfig( results );

		return results;
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getOverdueTasks( String recordId ) {

		System.debug( '\n------------------------------------------\n------------getOverdueTasks------------\n------------------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                              TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, false );

		List<TAG_ActivityTimelineModelList> data =              new List<TAG_ActivityTimelineModelList>();
		List<TAG_ActivityTimelineModel> overdue =               TAG_ActivityTimelineHelper.getOverdueOnly( sObjectsToQuery, recordId );
		overdue =                                               TAG_ActivityTimelineHelper.getOwnerAndContactNames( overdue );
		TAG_ActivityTimelineModelList overdueWrapper =          new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, overdue, false, true );
		data.add( overdueWrapper );

		data = TAG_ActivityTimelineHelper.removeConfig( data );

		return data;
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineParent__mdt> getTimelineObjects( String recordId ) {

		System.debug( '\n------------------------------------------\n------------getTimelineObjects------------\n------------------------------------------' );

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }

		String parentSObjectType =                              TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimelineParent__mdt> data =            TAG_ActivityTimelineHelper.getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes =                           TAG_ActivityTimelineHelper.getRecordTypes( data );

		if ( IS_NORWEGIAN ) {
			for ( TAG_ActivityTimelineParent__mdt mdt : data ) {
				mdt.Activity_Timeline_Child__r.CreateableObject_TextEnglish__c = mdt.Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c;
			}
		}

		for ( TAG_ActivityTimelineParent__mdt mdt : data ) {
			mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c = recordTypes.get( mdt.Activity_Timeline_Child__r.SObjectName__c + mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c );
		}

		return data;
	}
}
