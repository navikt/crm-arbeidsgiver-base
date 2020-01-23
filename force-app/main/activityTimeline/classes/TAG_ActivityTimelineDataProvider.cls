public with sharing class TAG_ActivityTimelineDataProvider {

	private static final List<String> CHILD_FIELDS_TO_QUERY = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c', 'SObjectAssigneeId__c', 'SObjectRelatedUserId__c', 'SObjectTypeField__c' };
	private static final User u = [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];

	@AuraEnabled(cacheable = false)
	public static List<TAG_ActivityTimelineModel> getTimelineItemData( String recordId ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType, false );
		List<String> queries = createSoqlQueries( sObjectsToQuery, recordId );
		List<SObject> sObjects = getSObjectsFromQueries( queries );
		List<TAG_ActivityTimelineModel> data = createActivityTimelineData( sObjectsToQuery, sObjects, u.LanguageLocaleKey );
		System.debug( 'data: ' + data );

		return data;
	}

	@AuraEnabled(cacheable = false)
	public static List<TAG_ActivityTimeline__mdt> getTimelineObjects( String recordId ) {
		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> data = getSObjectsToQuery( parentSObjectType, true );

		if ( u.LanguageLocaleKey == 'Norsk' ) {
			for ( TAG_ActivityTimeline__mdt mdt : data ) {
				mdt.CreatableObject_TextEnglish__c = mdt.CreatableObject_TextNorwegian__c;
			}
		}

		return data;
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
		                                                   CreatableObject_TextEnglish__c, CreatableObject_TextNorwegian__c, CreataleObject_RecordType__c,
		                                                   SObjectChild__c, SObjectParent__c,
		                                                   SObjectDateField__c,  SObjectTitle__c,
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

	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery, String recordId ) {

		List<String> queries = new List<String>();
		Boolean taskHasNotBeenQueried = true;

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {
			String fieldsToQuery = getFieldsToQueryFromMdt( mdt, CHILD_FIELDS_TO_QUERY );
			String query = 'SELECT Id, ' + fieldsToQuery + ' FROM ' + mdt.SObjectChild__c + ' WHERE ' + mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'';

			// append the Type = something parameter to the query
			if ( mdt.SObjectChild__c != 'Task' ) {
				if ( mdt.SObjectTypeField__c != null && mdt.SObjectTypeValue__c != null ) {
					if ( mdt.SObjectTypeValue__c.contains( ';' ) ) {
						query += ' AND ' + mdt.SObjectTypeField__c + ' IN (';
						for ( String type : mdt.SObjectTypeValue__c.split( ';' ) ) {
							query += '\'' + type + '\',';
						}
						query = query.removeEnd( ',' ) + ')';
					} else {
						query += ' AND ' + mdt.SObjectTypeField__c + ' = \'' + mdt.SObjectTypeValue__c + '\'';
					}
				}
				query = query.replaceAll( '\'null\'', 'null' );
				queries.add( query );
			}
			query = query.replaceAll( '\'null\'', 'null' );

			// just query all tasks but only once
			if ( mdt.SObjectChild__c == 'Task' && taskHasNotBeenQueried ) {
				queries.add( query );
				taskHasNotBeenQueried = false;
			}
		}

		return queries;
	}

	public static String getFieldsToQueryFromMdt( TAG_ActivityTimeline__mdt mdt, List<String> mdtFieldsToQuery ) {

		String fieldsToQuery = '';
		for ( String mdtField : mdtFieldsToQuery ) {
			String field = (String) mdt.get( mdtField );
			if ( field != null ) {
				if ( !fieldsToQuery.contains( field + ',' ) ) {
					fieldsToQuery +=  field + ',';
				}
			}
		}

		if ( mdt.SObjectChild__c == 'Task' ) {
			fieldsToQuery += 'Status,';
		}

		return fieldsToQuery.removeEnd( ',' );
	}

	public static List<SObject> getSObjectsFromQueries( List<String> queries ) {

		List<SObject> sObjects = new List<SObject>();

		for ( String query : queries ) {
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
