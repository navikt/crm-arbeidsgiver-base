public with sharing class TAG_ActivityTimelineDataProvider {

	private static final List<String> CHILD_FIELDS_TO_QUERY = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c', 'SObjectAssigneeId__c', 'SObjectRelatedUserId__c', 'SObjectTypeField__c' };
	private static final User USER = [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Datetime CURRENT_DATETIME = Datetime.now();
	private static final String CURRENT_MONTH = CURRENT_DATETIME.format( 'MMMMM' );
	private static final Datetime PREVIOUS_DATETIME = Datetime.now().addMonths( -1 );
	private static final String PREVIOUS_MONTH = PREVIOUS_DATETIME.format( 'MMMMM' );


	public class AmountOfRecords {
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public Integer amount { get; set; }
	}

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getTimelineItemData( String recordId, List<AmountOfRecords> amountOfRecords ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		Map<String, Integer> mapOfAmountParamenter = createMapOfAmountParamenter( amountOfRecords );
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType, false );
		List<TAG_ActivityTimelineModelList> data = query( sObjectsToQuery, recordId, mapOfAmountParamenter );

		return data;
	}

	public static Map<String, Integer> createMapOfAmountParamenter( List<AmountOfRecords> amountOfRecords ) {
		Map<String, Integer> mapOfAmountParamenter = new Map<String, Integer>();

		for ( AmountOfRecords row : amountOfRecords ) {
			mapOfAmountParamenter.put( row.id, row.amount );
		}

		return mapOfAmountParamenter;
	}

	public static List<TAG_ActivityTimelineModelList> query( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Map<String, Integer> mapOfAmountParamenter ) {

		List<TAG_ActivityTimelineModelList> data = new List<TAG_ActivityTimelineModelList>();

		Integer amountUpcoming = mapOfAmountParamenter.get( Label.ActTime_Upcoming );
		Integer amountThisMonth = mapOfAmountParamenter.get( Label.ActTime_ThisMonth );
		Integer amountPreviousMonth = mapOfAmountParamenter.get( Label.ActTime_PreviousMonth );
		Integer amountOlder = mapOfAmountParamenter.get( Label.ActTime_Older );

		List<String> upcomingQuery = createSoqlQueries( sObjectsToQuery, recordId, amountUpcoming, Label.ActTime_Upcoming );
		List<SObject> upcomingSObjects = getSObjectsFromQueries( upcomingQuery );
		List<TAG_ActivityTimelineModel> upcomingData = createActivityTimelineData( sObjectsToQuery, upcomingSObjects );

		List<String> thisAndPreviousMonthQuery = createSoqlQueries( sObjectsToQuery, recordId, null, Label.ActTime_ThisMonth );
		List<SObject> thisAndPreviousMonthSObjects = getSObjectsFromQueries( thisAndPreviousMonthQuery );
		List<TAG_ActivityTimelineModel> thisAndPreviousMonthData = createActivityTimelineData( sObjectsToQuery, thisAndPreviousMonthSObjects );

		List<String> olderQuery = createSoqlQueries( sObjectsToQuery, recordId, amountOlder, Label.ActTime_Older );
		List<SObject> olderSObjects = getSObjectsFromQueries( olderQuery );
		List<TAG_ActivityTimelineModel> olderData = createActivityTimelineData( sObjectsToQuery, olderSObjects );

		TAG_ActivityTimelineModelList upcomingWrapped =         new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcomingData, false );
		TAG_ActivityTimelineModelList thisMonthWrapped =        getCorrectMonthOnly( CURRENT_DATETIME.month(), new TAG_ActivityTimelineModelList( CURRENT_MONTH, Label.ActTime_ThisMonth, thisAndPreviousMonthData, false ) );
		TAG_ActivityTimelineModelList previousMonthWrapped =    getCorrectMonthOnly( PREVIOUS_DATETIME.month(),  new TAG_ActivityTimelineModelList( PREVIOUS_MONTH, Label.ActTime_PreviousMonth, thisAndPreviousMonthData, false ) );
		TAG_ActivityTimelineModelList overdueWrapped =          getOverdueOnly ( new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, thisAndPreviousMonthData, false ) );
		TAG_ActivityTimelineModelList olderWrapped =            new TAG_ActivityTimelineModelList( Label.ActTime_Older, Label.ActTime_Older, olderData, false );

		if ( overdueWrapped.models.size() > 0 ) {
			overdueWrapped = limitAmountOfRecords( overdueWrapped );
			data.add( overdueWrapped );
		} if ( upcomingWrapped.models.size() > 0 ) {
			upcomingWrapped = limitAmountOfRecords( upcomingWrapped );
			data.add( upcomingWrapped );
		} if ( thisMonthWrapped.models.size() > 0 ) {
			thisMonthWrapped = limitAmountOfRecords( thisMonthWrapped );
			data.add( thisMonthWrapped );
		} if ( thisMonthWrapped.models.size() > 0 ) {
			previousMonthWrapped = limitAmountOfRecords( previousMonthWrapped );
			data.add( previousMonthWrapped );
		} if ( olderWrapped.models.size() > 0 ) {
			olderWrapped = limitAmountOfRecords( olderWrapped );
			data.add( olderWrapped );
		}

		return data;
	}

	public static TAG_ActivityTimelineModelList limitAmountOfRecords( TAG_ActivityTimelineModelList wrapped ) {
		return wrapped; // TODO fix
	}

	public static TAG_ActivityTimelineModelList getCorrectMonthOnly( Integer month, TAG_ActivityTimelineModelList wrapper ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel wr : wrapper.models ) {
			if ( wr.record.dateValueDb.month() == month && !wr.record.overdue ) {
				tmpModels.add( wr );
			}
		}
		wrapper.models = tmpModels;

		return wrapper;
	}

	public static TAG_ActivityTimelineModelList getOverdueOnly( TAG_ActivityTimelineModelList wrapper ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel wr : wrapper.models ) {
			if ( wr.record.overdue ) {
				tmpModels.add( wr );
			}
		}
		wrapper.models = tmpModels;

		return wrapper;
	}

// TODO check if user can create records
	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data = getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes = getRecordTypes( data );

		if ( USER.LanguageLocaleKey == 'Norsk' ) {
			for ( TAG_ActivityTimeline__mdt mdt : data ) {
				mdt.CreatableObject_TextEnglish__c = mdt.CreatableObject_TextNorwegian__c;
			}
		}
		for ( TAG_ActivityTimeline__mdt mdt : data ) {
			mdt.CreatableObject_RecordType__c = recordTypes.get( mdt.SObjectChild__c + mdt.CreatableObject_RecordType__c );
		}

		return data;
	}

	public static Map<String, Id> getRecordTypes( List<TAG_ActivityTimeline__mdt> data ) {

		Set<String> recordTypeNames = new Set<String>();

		for ( TAG_ActivityTimeline__mdt mdt : data ) {
			if ( mdt.CreatableObject_RecordType__c != null ) {
				recordTypeNames.add( mdt.CreatableObject_RecordType__c );
			}
		}

		List<RecordType> recordTypes = [SELECT Id, Name, SobjectType FROM RecordType WHERE Name IN : recordTypeNames];
		Map<String, Id> recordTypeMap = new Map<String, Id>();
		for ( RecordType rt : recordTypes ) {
			recordTypeMap.put( rt.SobjectType + rt.Name, rt.Id );
		}

		return recordTypeMap;
	}

	public static String getSOjectTypeFromRecordId( String recordId ) {

		Id i = (Id) recordId;

		return String.valueOf( i.getSobjectType() );

	}

	public static List<TAG_ActivityTimeline__mdt> getSObjectsToQuery( String parentSObjectType, Boolean creatable ) {
		List<Boolean> allBools = new List<Boolean> { true, false };
		if ( creatable ) {
			allBools = new List<Boolean> { true };
		}

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
		                                                   SLDS_Timeline_Item__c, SLDS_Icon__c,
		                                                   CreatableObject_TextEnglish__c, CreatableObject_TextNorwegian__c, CreatableObject_RecordType__c,
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
		                                                       ( CreatableObject_Checkbox__c IN : allBools ) AND
		                                                       ( SObjectParent__c = : parentSObjectType ) AND
		                                                       ( IsActive__c = true )

		                                                   ORDER BY SObjectChild__c];

		if ( sObjectsToQuery.isEmpty() ) {
			throw new AuraException( Label.ActTime_NotConfugred );
		} else {

			// TODO check if user can read objects 👀
			return sObjectsToQuery;
		}
	}

	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Integer amount, String dateParameter ) {

		Set<String> queriedSobjects = new Set<String>();
		List<String> queries = new List<String>();
		Boolean taskHasNotBeenQueried = true;

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
			String query = ' SELECT Id, ' + fieldsToQuery +

			               ' FROM ' + mdt.SObjectChild__c +

			               ' WHERE ' + mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'' +
			               ' ' + getSoqlDateFromMonthPeriod( mdt, dateParameter ) +
			               ' AND ' + mdt.SObjectDateField__c + ' != null ' +

			               ' ORDER BY ' + mdt.SObjectDateField__c;

			if ( amount != null ) {
				query +=  ' LIMIT ' + amount;
			}


			if ( !queriedSobjects.contains( mdt.SObjectChild__c ) ) {
				queries.add( query );
				queriedSobjects.add( mdt.SObjectChild__c );
			}
		}

		return queries;
	}

	public static String getSoqlDateFromMonthPeriod( TAG_ActivityTimeline__mdt mdt, String dateParameter ) {

		String currentDate = '' + ( mdt.SObjectDateFieldIsDate__c ? System.today() : System.now() );
		if ( mdt.SObjectDateFieldIsDate__c ) {
			currentDate = currentDate.replaceAll( ' 00:00:00', '' );
		} else {
			currentDate = currentDate.replaceAll( ' ', 'T' ) + 'Z';
		}


		if ( dateParameter == Label.ActTime_Upcoming ) {
			return 'AND ' + mdt.SObjectDateField__c + ' > ' + currentDate;
		} else if ( dateParameter == Label.ActTime_ThisMonth ) {
			return 'AND ' + mdt.SObjectDateField__c + ' < ' + currentDate +
			       'AND ( ' +
			       mdt.SObjectDateField__c + '= THIS_MONTH OR ' +
			       mdt.SObjectDateField__c + ' = LAST_N_MONTHS:1 ) ';
		} else if ( dateParameter == Label.ActTime_Older ) {
			return 'AND ' + mdt.SObjectDateField__c + ' < LAST_N_MONTHS:1';
		} else {
			return '';
		}

	}

	public static String getFieldsToQueryFromMdt( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, TAG_ActivityTimeline__mdt currentObject ) {

		Set<String> fieldsToQuery = new Set<String>();
		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			if ( mdt.SObjectChild__c == currentObject.SObjectChild__c ) {

				for ( String mdtField : CHILD_FIELDS_TO_QUERY ) {
					String field = (String) mdt.get( mdtField );
					if ( field != null ) {
						fieldsToQuery.add( field );
					}
				}
			}
		}

		if ( currentObject.SObjectChild__c == 'Task' ) {
			fieldsToQuery.add( 'Status' );
		}

		List<String> res = new List<String>();
		res.addAll( fieldsToQuery );

		return string.join( res, ',' );
	}

	public static List<SObject> getSObjectsFromQueries( List<String> queries ) {

		List<SObject> sObjects = new List<SObject>();

		for ( String query : queries ) {
			System.debug( 'query: ' + query );
			List<SObject> sObjs = Database.query( query );
			sObjects.addAll( sObjs );
		}

		return sObjects;
	}

	public static List<TAG_ActivityTimelineModel> createActivityTimelineData( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, List<SObject> sObjects ) {

		List<TAG_ActivityTimelineModel> data = new List<TAG_ActivityTimelineModel>();
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig( sObjectsToQuery );

		for ( SObject sObj : sObjects ) {
			String childSObjectKind = getSOjectTypeFromRecordId( (Id) sObj.get( 'Id' ) );
			String childSObjectType = '';
			for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQueryMap.values() ) {
				if ( mdt.SObjectChild__c == childSObjectKind ) {
					if ( mdt.SObjectTypeField__c != null ) {
						String type = (String) sObj.get( mdt.SObjectTypeField__c );
						if ( type != null ) {
							childSObjectType = type;
							break;
						}
					}
				}
			}

			TAG_ActivityTimeline__mdt mdt = sObjectsToQueryMap.get( childSObjectKind + childSObjectType );
			if ( mdt == null ) {
				mdt = sObjectsToQueryMap.get( childSObjectKind );
			}

			if ( mdt != null ) {
				data.add( new TAG_ActivityTimelineModel( mdt, sObj, USER.LanguageLocaleKey ) );
			}
		}

		return data;
	}

	public static Map<String, TAG_ActivityTimeline__mdt> getMapOfActivityTimelineConfig( List<TAG_ActivityTimeline__mdt> sObjectsToQuery ) {
		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = new Map<String, TAG_ActivityTimeline__mdt>();

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String mdtType = mdt.SObjectTypeValue__c != null && mdt.SObjectTypeValue__c != 'null' ? mdt.SObjectTypeValue__c : '';
			if ( mdtType.contains( ';' ) ) {
				List<String> typeList = mdtType.split( ';' );
				for ( String type : typeList ) {
					sObjectsToQueryMap.put( mdt.SObjectChild__c + type, mdt );
				}
			} else {
				sObjectsToQueryMap.put( mdt.SObjectChild__c + mdtType, mdt );
			}
		}

		return sObjectsToQueryMap;
	}
}
