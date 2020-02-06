public with sharing class TAG_ActivityTimelineDataProvider {

	private static final User USER =                            [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =                 USER.LanguageLocaleKey == 'Norsk';

	private static final List<String> MONTH_NAME =              new List<String> {null, 'Januar', 'Februar', 'Mars', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Desember'};
	private static final Datetime CURRENT_DATETIME =            Datetime.now();
	private static final String CURRENT_MONTH =                 IS_NORWEGIAN ? MONTH_NAME[CURRENT_DATETIME.month()] : CURRENT_DATETIME.format( 'MMMMM' );
	private static final Datetime PREVIOUS_DATETIME =           Datetime.now().addMonths( -1 );
	private static final String PREVIOUS_MONTH =                IS_NORWEGIAN ? MONTH_NAME[PREVIOUS_DATETIME.month()] : PREVIOUS_DATETIME.format( 'MMMMM' );

	public class AmountOfRecords {
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public String idUpdated { get; set; }
		@AuraEnabled public Integer amount { get; set; }
		@AuraEnabled public Integer previousAmount { get; set; }
		@AuraEnabled public Boolean loadedAll { get; set; }
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getTimelineItemData( String recordId, List<AmountOfRecords> amountOfRecords ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		Map<String, AmountOfRecords> mapOfAmountParamenter = createMapOfAmountParamenter( amountOfRecords );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType, false );
		List<TAG_ActivityTimelineModelList> data = query( sObjectsToQuery, recordId, mapOfAmountParamenter );

		return data;
	}

	public static Map<String, AmountOfRecords> createMapOfAmountParamenter( List<AmountOfRecords> amountOfRecords ) {
		Map<String, AmountOfRecords> mapOfAmountParamenter = new Map<String, AmountOfRecords>();

		for ( AmountOfRecords row : amountOfRecords ) {
			mapOfAmountParamenter.put( row.id, row );
		}

		return mapOfAmountParamenter;
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

		                                                   ORDER BY SObjectChild__c];

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


	public static List<TAG_ActivityTimelineModelList> query( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Map<String, AmountOfRecords> mapOfAmountParamenter ) {

		List<TAG_ActivityTimelineModelList> data = new List<TAG_ActivityTimelineModelList>();

		Integer amountOverdue =         mapOfAmountParamenter.get( Label.ActTime_Overdue ).amount;
		Integer amountUpcoming =        mapOfAmountParamenter.get( Label.ActTime_Upcoming ).amount;
		Integer amountThisMonth =       mapOfAmountParamenter.get( Label.ActTime_ThisMonth ).amount;
		Integer amountPreviousMonth =   mapOfAmountParamenter.get( Label.ActTime_PreviousMonth ).amount;
		Integer amountOlder =           mapOfAmountParamenter.get( Label.ActTime_Older ).amount;

		Integer previousAmountOverdue =         mapOfAmountParamenter.get( Label.ActTime_Overdue ).previousAmount;
		Integer previousAmountUpcoming =        mapOfAmountParamenter.get( Label.ActTime_Upcoming ).previousAmount;
		Integer previousAmountThisMonth =       mapOfAmountParamenter.get( Label.ActTime_ThisMonth ).previousAmount;
		Integer previousAmountPreviousMonth =   mapOfAmountParamenter.get( Label.ActTime_PreviousMonth ).previousAmount;
		Integer previousAmountOlder =           mapOfAmountParamenter.get( Label.ActTime_Older ).previousAmount;

		Boolean previousLoadedOverdue =         mapOfAmountParamenter.get( Label.ActTime_Overdue ).loadedAll;
		Boolean previousLoadedUpcoming =        mapOfAmountParamenter.get( Label.ActTime_Upcoming ).loadedAll;
		Boolean previousLoadedThisMonth =       mapOfAmountParamenter.get( Label.ActTime_ThisMonth ).loadedAll;
		Boolean previousLoadedPreviousMonth =   mapOfAmountParamenter.get( Label.ActTime_PreviousMonth ).loadedAll;
		Boolean previousLoadedOlder =           mapOfAmountParamenter.get( Label.ActTime_Older ).loadedAll;

		String idUpdated =           mapOfAmountParamenter.get( Label.ActTime_Older ).idUpdated;

		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = TAG_ActivityTimelineHelper.getMapOfActivityTimelineConfig( sObjectsToQuery );
		List<TAG_ActivityTimeline__mdt> taskMdt = new List<TAG_ActivityTimeline__mdt> { sObjectsToQueryMap.get( 'Task' ) };

		List<String>                    overdueQuery =          TAG_ActivityTimelineHelper.createSoqlQueries( taskMdt, recordId, amountOverdue, Label.ActTime_Overdue, 'desc' );
		List<SObject>                   overdueSObjects =       TAG_ActivityTimelineHelper.getSObjectsFromQueries( overdueQuery );
		List<TAG_ActivityTimelineModel> overdueData =           TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, overdueSObjects );
		Boolean loadedAllOverdue =                              (overdueData.size() == previousAmountOverdue && idUpdated == Label.ActTime_Overdue) || previousLoadedOverdue;

		List<String>                    upcomingQuery =         TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, amountUpcoming, Label.ActTime_Upcoming, 'asc' );
		List<SObject>                   upcomingSObjects =      TAG_ActivityTimelineHelper.getSObjectsFromQueries( upcomingQuery );
		List<TAG_ActivityTimelineModel> upcomingData =          TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, upcomingSObjects );
		Boolean loadedAllUpcoming =                             (upcomingData.size() == previousAmountUpcoming && idUpdated == Label.ActTime_Upcoming) || previousLoadedUpcoming;

		List<String>                    thisAndPrevMonthQuery = TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, null, Label.ActTime_ThisMonth, 'desc' );
		List<SObject>                   thisAndPrevMonthSObj =  TAG_ActivityTimelineHelper.getSObjectsFromQueries( thisAndPrevMonthQuery );
		List<TAG_ActivityTimelineModel> thisAndPrevMonthData =  TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, thisAndPrevMonthSObj );
		List<TAG_ActivityTimelineModel> thisMonthData =         TAG_ActivityTimelineHelper.getCorrectMonthOnly( PREVIOUS_DATETIME.month(), thisAndPrevMonthData );
		List<TAG_ActivityTimelineModel> previousMonthData =     TAG_ActivityTimelineHelper.getCorrectMonthOnly( CURRENT_DATETIME.month(),  thisAndPrevMonthData );
		Boolean loadedAllThisMonth =                            (thisMonthData.size() == previousAmountThisMonth && idUpdated == Label.ActTime_ThisMonth) || previousLoadedThisMonth;
		Boolean loadedAllPreviousMonth =                        (previousMonthData.size() == previousAmountPreviousMonth && idUpdated == Label.ActTime_PreviousMonth) || previousLoadedPreviousMonth;

		List<String>                    olderQuery =            TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, amountOlder, Label.ActTime_Older, 'desc' );
		List<SObject>                   olderSObjects =         TAG_ActivityTimelineHelper.getSObjectsFromQueries( olderQuery );
		List<TAG_ActivityTimelineModel> olderData =             TAG_ActivityTimelineHelper.removeOverdue( TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, olderSObjects ) );
		Boolean loadedAllOlder =                                (olderData.size() == previousAmountOlder && idUpdated == Label.ActTime_Older) || previousLoadedOlder;

		TAG_ActivityTimelineModelList overdueWrapped =          new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, overdueData, loadedAllOverdue, true );
		TAG_ActivityTimelineModelList upcomingWrapped =         new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcomingData, loadedAllUpcoming, false );
		TAG_ActivityTimelineModelList thisMonthWrapped =        new TAG_ActivityTimelineModelList( Label.ActTime_ThisMonth, CURRENT_MONTH, thisMonthData, loadedAllThisMonth, true );
		TAG_ActivityTimelineModelList previousMonthWrapped =    new TAG_ActivityTimelineModelList( Label.ActTime_PreviousMonth, PREVIOUS_MONTH, previousMonthData, loadedAllPreviousMonth, true );
		TAG_ActivityTimelineModelList olderWrapped =            new TAG_ActivityTimelineModelList( Label.ActTime_Older, Label.ActTime_Older, olderData, loadedAllOlder, true );

		if ( overdueWrapped.models.size() > 0 ) {
			overdueWrapped =        TAG_ActivityTimelineHelper.limitAmountOfRecords( overdueWrapped, amountOverdue );
			data.add( overdueWrapped );
		} if ( upcomingWrapped.models.size() > 0 ) {
			upcomingWrapped =       TAG_ActivityTimelineHelper.limitAmountOfRecords( upcomingWrapped, amountUpcoming );
			data.add( upcomingWrapped );
		} if ( thisMonthWrapped.models.size() > 0 ) {
			thisMonthWrapped =      TAG_ActivityTimelineHelper.limitAmountOfRecords( thisMonthWrapped, amountThisMonth );
			data.add( thisMonthWrapped );
		} if ( previousMonthWrapped.models.size() > 0 ) {
			previousMonthWrapped =  TAG_ActivityTimelineHelper.limitAmountOfRecords( previousMonthWrapped, amountPreviousMonth );
			data.add( previousMonthWrapped );
		} if ( olderWrapped.models.size() > 0 ) {
			olderWrapped =          TAG_ActivityTimelineHelper.limitAmountOfRecords( olderWrapped, amountOlder );
			data.add( olderWrapped );
		}

		return data;
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