public with sharing class TAG_ActivityTimelineController {

	private static final User USER =                [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =     USER.LanguageLocaleKey == 'Norsk';

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getTimelineItemData( String recordId, Integer amountOfMonths ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType, false );
		List<TAG_ActivityTimelineModelList> data = query( sObjectsToQuery, recordId, amountOfMonths );

		return data;
	}

	public static List<TAG_ActivityTimeline__mdt> getSObjectsToQuery( String parentSObjectType, Boolean createable ) {
		List<Boolean> allBools = new List<Boolean> { true, false };
		if ( createable ) {
			allBools = new List<Boolean> { true };
		}

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
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
		                                                       ( CreateableObject_Checkbox__c IN : allBools ) AND
		                                                       ( SObjectParent__c = : parentSObjectType ) AND
		                                                       ( IsActive__c = true )

		                                                   ORDER BY SObjectChild__c, CreateableObject_TextNorwegian__c];

		if ( sObjectsToQuery.isEmpty() ) {
			throw new AuraException( Label.ActTime_NotConfugred );
		} else {

			List<TAG_ActivityTimeline__mdt> sObjectsToUse = new List<TAG_ActivityTimeline__mdt>();

			for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
				if ( createable && TAG_ActivityTimelineHelper.isCreateable( mdt.SObjectChild__c ) ) {
					sObjectsToUse.add( mdt );
				} else if ( !createable && TAG_ActivityTimelineHelper.isAccessible( mdt.SObjectChild__c ) ) {
					sObjectsToUse.add( mdt );
				}
			}

			return sObjectsToUse;
		}
	}


	public static List<TAG_ActivityTimelineModelList> query( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Integer amountOfMonths ) {

		List<TAG_ActivityTimelineModelList> results = new List<TAG_ActivityTimelineModelList>();

		List<String>                    query =          TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, amountOfMonths );
		List<SObject>                   sObjects =       TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data =           TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );
		data.sort();
		List<TAG_ActivityTimelineModel> overdue =   TAG_ActivityTimelineHelper.getOverdueOnly( data );
		List<TAG_ActivityTimelineModel> upcoming =  TAG_ActivityTimelineHelper.getUpcomingOnly( data );

		TAG_ActivityTimelineModelList wrappedOverdue =          new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, overdue, false, true );
		TAG_ActivityTimelineModelList wrappedUpcoming =          new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcoming, false, false );
		List<TAG_ActivityTimelineModelList> wrappedMonths =          TAG_ActivityTimelineHelper.getRecordsDividedIntoMonths( data );

		results.add( wrappedOverdue );
		results.add( wrappedUpcoming );
		results.addAll( wrappedMonths );

		return results;
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data = getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes = TAG_ActivityTimelineHelper.getRecordTypes( data );

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