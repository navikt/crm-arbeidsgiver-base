public with sharing class TAG_ActivityTimelineDataProvider {

	private static final List<String> CHILD_FIELDS_TO_QUERY =   new List<String> { 'SObjectDateField__c', 'SObjectTitle__c', 'SObjectAssigneeId__c', 'SObjectRelatedUserId__c', 'SObjectTypeField__c' };
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

		System.debug( 'amountOfRecords: ' + amountOfRecords );
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
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

		Map<String, TAG_ActivityTimeline__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig( sObjectsToQuery );
		List<TAG_ActivityTimeline__mdt> taskMdt = new List<TAG_ActivityTimeline__mdt> { sObjectsToQueryMap.get( 'Task' ) };

		List<String>                    overdueQuery =          createSoqlQueries( taskMdt, recordId, amountOverdue, Label.ActTime_Overdue, 'desc' );
		List<SObject>                   overdueSObjects =       getSObjectsFromQueries( overdueQuery );
		List<TAG_ActivityTimelineModel> overdueData =           createActivityTimelineData( sObjectsToQuery, overdueSObjects );
		Boolean loadedAllOverdue =                              (overdueData.size() == previousAmountOverdue && idUpdated == Label.ActTime_Overdue) || previousLoadedOverdue;

		List<String>                    upcomingQuery =         createSoqlQueries( sObjectsToQuery, recordId, amountUpcoming, Label.ActTime_Upcoming, 'asc' );
		List<SObject>                   upcomingSObjects =      getSObjectsFromQueries( upcomingQuery );
		List<TAG_ActivityTimelineModel> upcomingData =          createActivityTimelineData( sObjectsToQuery, upcomingSObjects );
		Boolean loadedAllUpcoming =                             (upcomingData.size() == previousAmountUpcoming && idUpdated == Label.ActTime_Upcoming) || previousLoadedUpcoming;

		List<String>                    thisAndPrevMonthQuery = createSoqlQueries( sObjectsToQuery, recordId, null, Label.ActTime_ThisMonth, 'desc' );
		List<SObject>                   thisAndPrevMonthSObj =  getSObjectsFromQueries( thisAndPrevMonthQuery );
		List<TAG_ActivityTimelineModel> thisAndPrevMonthData =  createActivityTimelineData( sObjectsToQuery, thisAndPrevMonthSObj );
		List<TAG_ActivityTimelineModel> thisMonthData =         getCorrectMonthOnly( PREVIOUS_DATETIME.month(), thisAndPrevMonthData );
		List<TAG_ActivityTimelineModel> previousMonthData =     getCorrectMonthOnly( CURRENT_DATETIME.month(),  thisAndPrevMonthData );
		Boolean loadedAllThisMonth =                            (thisMonthData.size() == previousAmountThisMonth && idUpdated == Label.ActTime_ThisMonth) || previousLoadedThisMonth;
		Boolean loadedAllPreviousMonth =                        (previousMonthData.size() == previousAmountPreviousMonth && idUpdated == Label.ActTime_PreviousMonth) || previousLoadedPreviousMonth;

		List<String>                    olderQuery =            createSoqlQueries( sObjectsToQuery, recordId, amountOlder, Label.ActTime_Older, 'desc' );
		List<SObject>                   olderSObjects =         getSObjectsFromQueries( olderQuery );
		List<TAG_ActivityTimelineModel> olderData =             removeOverdue( createActivityTimelineData( sObjectsToQuery, olderSObjects ) );
		Boolean loadedAllOlder =                                (olderData.size() == previousAmountOlder && idUpdated == Label.ActTime_Older) || previousLoadedOlder;

		TAG_ActivityTimelineModelList overdueWrapped =          new TAG_ActivityTimelineModelList( Label.ActTime_Overdue, Label.ActTime_Overdue, overdueData, loadedAllOverdue, true );
		TAG_ActivityTimelineModelList upcomingWrapped =         new TAG_ActivityTimelineModelList( Label.ActTime_Upcoming, Label.ActTime_Upcoming, upcomingData, loadedAllUpcoming, false );
		TAG_ActivityTimelineModelList thisMonthWrapped =        new TAG_ActivityTimelineModelList( Label.ActTime_ThisMonth, CURRENT_MONTH, thisMonthData, loadedAllThisMonth, true );
		TAG_ActivityTimelineModelList previousMonthWrapped =    new TAG_ActivityTimelineModelList( Label.ActTime_PreviousMonth, PREVIOUS_MONTH, previousMonthData, loadedAllPreviousMonth, true );
		TAG_ActivityTimelineModelList olderWrapped =            new TAG_ActivityTimelineModelList( Label.ActTime_Older, Label.ActTime_Older, olderData, loadedAllOlder, true );

		if ( overdueWrapped.models.size() > 0 ) {
			overdueWrapped =        limitAmountOfRecords( overdueWrapped, amountOverdue );
			data.add( overdueWrapped );
		} if ( upcomingWrapped.models.size() > 0 ) {
			upcomingWrapped =       limitAmountOfRecords( upcomingWrapped, amountUpcoming );
			data.add( upcomingWrapped );
		} if ( thisMonthWrapped.models.size() > 0 ) {
			thisMonthWrapped =      limitAmountOfRecords( thisMonthWrapped, amountThisMonth );
			data.add( thisMonthWrapped );
		} if ( previousMonthWrapped.models.size() > 0 ) {
			previousMonthWrapped =  limitAmountOfRecords( previousMonthWrapped, amountPreviousMonth );
			data.add( previousMonthWrapped );
		} if ( olderWrapped.models.size() > 0 ) {
			olderWrapped =          limitAmountOfRecords( olderWrapped, amountOlder );
			data.add( olderWrapped );
		}

		return data;
	}

	public static TAG_ActivityTimelineModelList limitAmountOfRecords( TAG_ActivityTimelineModelList wrapped, Integer amount ) {
		List<Object> castedObjects = (List<Object>) wrapped.models;
		List<TAG_ActivityTimelineModel> models = (List<TAG_ActivityTimelineModel>) TAG_ActivityTimelineDataProviderHelper.slice( castedObjects, 0, amount );
		wrapped.models = models;

		return wrapped;
	}

	public static List<TAG_ActivityTimelineModel> getCorrectMonthOnly( Integer month, List<TAG_ActivityTimelineModel> models ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel wr : models ) {
			if ( wr.record.dateValueDb.month() == month && !wr.record.overdue ) {
				tmpModels.add( wr );
			}
		}

		return tmpModels;
	}

	public static List<TAG_ActivityTimelineModel> removeOverdue( List<TAG_ActivityTimelineModel> models ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel wr : models ) {
			if ( !wr.record.overdue ) {
				tmpModels.add( wr );
			}
		}

		return tmpModels;
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

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data = getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes = getRecordTypes( data );

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

	public static Map<String, Id> getRecordTypes( List<TAG_ActivityTimeline__mdt> data ) {

		Set<String> recordTypeNames = new Set<String>();

		for ( TAG_ActivityTimeline__mdt mdt : data ) {
			if ( mdt.CreateableObject_RecordType__c != null ) {
				recordTypeNames.add( mdt.CreateableObject_RecordType__c );
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
				if ( createable && isCreateable( mdt.SObjectChild__c ) ) {
					sObjectsToUse.add( mdt );
				} else if ( !createable && isAccessible( mdt.SObjectChild__c ) ) {
					sObjectsToUse.add( mdt );
				}
			}

			return sObjectsToUse;
		}
	}

	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Integer amount, String dateParameter, String ascOrDesc ) {

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

			               ' ORDER BY ' + mdt.SObjectDateField__c +
			               ' ' + ascOrDesc;

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



		if ( dateParameter == Label.ActTime_Overdue ) {
			return 'AND ' + mdt.SObjectDateField__c + ' < ' + currentDate +
			       ' AND Status != \'Completed\'';
		} else if ( dateParameter == Label.ActTime_Upcoming ) {
			return 'AND ' + mdt.SObjectDateField__c + ' >= ' + currentDate;
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

	public static Boolean isCreateable( String sObjectType ) {
		return Schema.getGlobalDescribe().get( sObjectType ).getDescribe().isCreateable();
	}

	public static Boolean isAccessible( String sObjectType ) {
		return Schema.getGlobalDescribe().get( sObjectType ).getDescribe().isAccessible();
	}
}
