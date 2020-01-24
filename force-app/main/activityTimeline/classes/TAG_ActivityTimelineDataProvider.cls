public with sharing class TAG_ActivityTimelineDataProvider {

	private static final List<String> CHILD_FIELDS_TO_QUERY = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c', 'SObjectAssigneeId__c', 'SObjectRelatedUserId__c', 'SObjectTypeField__c' };
	private static final User u = [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];

	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimelineModelList> getTimelineItemData( String recordId ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType, false );

		List<String> periods = new List<String> { Label.ActTime_Overdue, Label.ActTime_Upcoming, Label.ActTime_ThisMonth, Label.ActTime_PreviousMonth, Label.ActTime_Older };
		List<TAG_ActivityTimelineModelList> data = new List<TAG_ActivityTimelineModelList>();
		for ( String p : periods ) {
			List<String> queries = createSoqlQueries( sObjectsToQuery, recordId, 5, p );
			List<SObject> sObjects = getSObjectsFromQueries( queries );
			List<TAG_ActivityTimelineModel> row = createActivityTimelineData( sObjectsToQuery, sObjects, u.LanguageLocaleKey );
			TAG_ActivityTimelineModelList d = new TAG_ActivityTimelineModelList( p + '', p + '', row );
			data.add( d );
		}

		return data;
	}

// TODO check if user can create records
	@AuraEnabled(cacheable = true)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data = getSObjectsToQuery( parentSObjectType, true );

		Map<String, Id> recordTypes = getRecordTypes( data );

		if ( u.LanguageLocaleKey == 'Norsk' ) {
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
		                                                   WHERE SObjectParent__c = : parentSObjectType AND CreatableObject_Checkbox__c IN : allBools
		                                                                            ORDER BY SObjectChild__c];

		if ( sObjectsToQuery.isEmpty() ) {
			throw new AuraException( 'Error. Not configured for this SObject type.' );
		} else {
			return sObjectsToQuery;
		}
	}

	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId, Integer amount, String period ) {

		Set<String> queriedSobjects = new Set<String>();
		List<String> queries = new List<String>();
		Boolean taskHasNotBeenQueried = true;

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = getFieldsToQueryFromMdt( sObjectsToQuery, mdt );
			String query = 'SELECT Id, ' + fieldsToQuery +
			               ' FROM ' + mdt.SObjectChild__c +
			               ' WHERE ' + mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'' +
			               ' ' + getSoqlDateFromMonthPeriod( mdt, period ) +
			               ' AND ' + mdt.SObjectDateField__c + ' != null ' +
			               ' ORDER BY ' + mdt.SObjectDateField__c;

			if ( !queriedSobjects.contains( mdt.SObjectChild__c ) ) {
				queries.add( query );
				queriedSobjects.add( mdt.SObjectChild__c );
			}
		}

		return queries;
	}

	public static String getSoqlDateFromMonthPeriod( TAG_ActivityTimeline__mdt mdt, String period ) {

		if ( period == Label.ActTime_Overdue ) {
			return '';
		} else if ( period == Label.ActTime_Upcoming ) {
			String d = '' + ( mdt.SObjectDateFieldIsDate__c ? System.today() : System.now() );
			if ( !mdt.SObjectDateFieldIsDate__c ) {
				d = d.replaceAll( ' ', 'T' ) + 'Z';
			} else {
				d = d.replaceAll( ' 00:00:00', '' );
			}

			return 'AND ' + mdt.SObjectDateField__c + ' > ' + d;
		} else if ( period == Label.ActTime_ThisMonth ) {
			return 'AND ' + mdt.SObjectDateField__c + ' = THIS_MONTH';
		} else if ( period == Label.ActTime_PreviousMonth ) {
			return 'AND ' + mdt.SObjectDateField__c + ' = NEXT_N_MONTHS:1';
		} else if ( period == Label.ActTime_Older ) {
			return '';
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

	public static List<TAG_ActivityTimelineModel> createActivityTimelineData( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, List<SObject> sObjects, String lang ) {

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
				data.add( new TAG_ActivityTimelineModel( mdt, sObj, lang ) );
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
