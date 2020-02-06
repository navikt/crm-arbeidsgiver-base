public with sharing class TAG_ActivityTimelineHelper {

	private static final List<String> CHILD_FIELDS_TO_QUERY =   new List<String> { 'SObjectDateField__c', 'SObjectTitle__c', 'SObjectAssigneeId__c', 'SObjectRelatedUserId__c', 'SObjectTypeField__c' };
	private static final User USER =                            [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =                 USER.LanguageLocaleKey == 'Norsk';

	private static final List<String> MONTH_NAME =              new List<String> {null, 'Januar', 'Februar', 'Mars', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Desember'};
	private static final List<String> MONTH_NAME_EN =           new List<String> {null, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};

	public static String getSOjectTypeFromRecordId( String recordId ) {
		Id i = (Id) recordId;

		return String.valueOf( i.getSobjectType() );
	}


	public static TAG_ActivityTimelineModelList limitAmountOfRecords( TAG_ActivityTimelineModelList wrapped, Integer amount ) {
		if ( wrapped.models.size() > 0 ) {
			List<Object> castedObjects = (List<Object>) wrapped.models;
			List<TAG_ActivityTimelineModel> models = (List<TAG_ActivityTimelineModel>) TAG_ActivityTimelineHelper.slice( castedObjects, 0, amount );
			wrapped.models = models;
		}

		return wrapped;
	}

	public static String getMonth( Integer monthNo ) {
		return IS_NORWEGIAN ? MONTH_NAME[monthNo] : MONTH_NAME_EN[monthNo];
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

	public static List<TAG_ActivityTimelineModel> getOverdueOnly( List<TAG_ActivityTimelineModel> models ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel model : models ) {
			if ( model.record.overdue ) {
				tmpModels.add( model );
			}
		}

		return tmpModels;
	}

	public static List<TAG_ActivityTimelineModel> getUpcomingOnly( List<TAG_ActivityTimelineModel> models ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel model : models ) {

			Datetime d = model.config.SObjectDateFieldIsDate__c ? System.today() : System.now();

			if ( model.record.dateValueDb >= d ) {
				tmpModels.add( model );
			}
		}

		return tmpModels;
	}

	public static List<TAG_ActivityTimelineModelList> getRecordsDividedIntoMonths( List<TAG_ActivityTimelineModel> data ) {

		Map<String, List<TAG_ActivityTimelineModel> > modelsSeparatedByMonth = new Map<String, List<TAG_ActivityTimelineModel> > ();

		for ( TAG_ActivityTimelineModel model : data ) {

			Datetime d = model.config.SObjectDateFieldIsDate__c ? System.today() : System.now();

			if ( model.record.dateValueDb < d ) {
				String key = model.record.dateValueDb.month() + '' + model.record.dateValueDb.year();
				if ( modelsSeparatedByMonth.containsKey( key ) ) {
					modelsSeparatedByMonth.get( key ).add( model );
				} else {
					modelsSeparatedByMonth.put( key, new List<TAG_ActivityTimelineModel> { model } );
				}
			}
		}
		List<TAG_ActivityTimelineModelList> results = new List<TAG_ActivityTimelineModelList>();

		for ( String key : modelsSeparatedByMonth.keySet() ) {
			Datetime d = modelsSeparatedByMonth.get( key )[0].record.dateValueDb;
			String name = getMonth( d.month() ) + ' ' + d.year();
			results.add( new TAG_ActivityTimelineModelList( key, name, modelsSeparatedByMonth.get( key ), false, true ) );
		}

		return results;
	}

	public static List<Object> slice( List<Object> input, Integer start, Integer endAmount ) {
		List<Object> output = input.clone();
		for ( Integer i = 0; i < start; i++ ) output.remove( 0 );
		Integer elements = endAmount - start;
		while ( output.size() > elements ) output.remove( elements );

		return output;
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



	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Integer amount, String dateParameter, Boolean isDescending ) {
// todo remove remove isDescending
		Set<String> queriedSobjects = new Set<String>();
		List<String> queries = new List<String>();
		Boolean taskHasNotBeenQueried = true;

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {

			String lastYear = '' + ( mdt.SObjectDateFieldIsDate__c ? System.today().addYears( -1 ) : System.now().addYears( -1 ) );
			if ( mdt.SObjectDateFieldIsDate__c ) {
				lastYear = lastYear.replaceAll( ' 00:00:00', '' );
			} else {
				lastYear = lastYear.replaceAll( ' ', 'T' ) + 'Z';
			}

			String fieldsToQuery = getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
			String query = ' SELECT Id, ' + fieldsToQuery +

			               ' FROM ' + mdt.SObjectChild__c +

			               ' WHERE ' + mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'' +
			               ' AND ' + mdt.SObjectDateField__c + ' > ' + lastYear +
			               ' AND ' + mdt.SObjectDateField__c + ' != null ' +

			               ' ORDER BY ' + mdt.SObjectDateField__c;

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
