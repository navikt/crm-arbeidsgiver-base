public with sharing class TAG_ActivityTimelineHelper {

	private static final List<String> CHILD_FIELDS_TO_QUERY =   new List<String> { 'Activity_Timeline_Child__r.SObjectDateField__c', 'Activity_Timeline_Child__r.SObjectTitle__c', 'SObjectAssigneeId__c', 'Activity_Timeline_Child__r.SObjectRelatedUserId__c', 'Activity_Timeline_Child__r.SObjectTypeField__c' };
	private static final User USER =                            [SELECT toLabel( LanguageLocaleKey ) FROM User WHERE Id = :UserInfo.getUserId()];
	private static final Boolean IS_NORWEGIAN =                 USER.LanguageLocaleKey == 'Norsk';

	private static final List<String> MONTH_NAME =              new List<String> {null, 'Januar', 'Februar', 'Mars', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Desember'};
	private static final List<String> MONTH_NAME_EN =           new List<String> {null, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};

	public static String getSOjectTypeFromRecordId( String recordId ) {
		Id i = (Id) recordId;

		return String.valueOf( i.getSobjectType() );
	}

	public static List<TAG_ActivityTimelineParent__mdt> getSObjectsToQuery( String parentSObjectType, Boolean createable ) {
		List<Boolean> allBools = new List<Boolean> { true, false, null };
		List<Boolean> allActiveBools = new List<Boolean> { true };
		if ( createable ) {
			allBools = new List<Boolean> { true };
			allActiveBools = new List<Boolean> { true, false, null };
		}

		List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery = [SELECT Id,

		                                                         SObjectAssigneeId__c, SObjectParent__c, SObjectRelationshipField__c,

		                                                         Activity_Timeline_Child__r.SLDS_Timeline_Color__c, Activity_Timeline_Child__r.SLDS_Icon__c, Activity_Timeline_Child__r.SLDS_Dropdown_Icon__c,
		                                                         Activity_Timeline_Child__r.CreateableObject_TextEnglish__c, Activity_Timeline_Child__r.CreateableObject_TextNorwegian__c, Activity_Timeline_Child__r.CreateableObject_RecordType__c,
		                                                         Activity_Timeline_Child__r.SObjectDateField__c, Activity_Timeline_Child__r.SObjectDateFieldIsDate__c,
		                                                         Activity_Timeline_Child__r.SObjectTypeField__c, Activity_Timeline_Child__r.SObjectTypeValue__c,
		                                                         Activity_Timeline_Child__r.SObjectTitle__c, Activity_Timeline_Child__r.SObjectName__c,
		                                                         Activity_Timeline_Child__r.SObjectRelatedUserId__c,
		                                                         Activity_Timeline_Child__r.CreateableObject_Field1__c, Activity_Timeline_Child__r.CreateableObject_Value1__c,
		                                                         Activity_Timeline_Child__r.CreateableObject_Field2__c, Activity_Timeline_Child__r.CreateableObject_Value2__c,
		                                                         Activity_Timeline_Child__r.CreateableObject_Field3__c, Activity_Timeline_Child__r.CreateableObject_Value3__c,
		                                                         Activity_Timeline_Child__r.SubtitlePastEnglish__c, Activity_Timeline_Child__r.SubtitlePastNorwegian__c,
		                                                         Activity_Timeline_Child__r.SubtitleFutureEnglish__c, Activity_Timeline_Child__r.SubtitleFutureNorwegian__c,
		                                                         Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c, Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c

		                                                         FROM TAG_ActivityTimelineParent__mdt

		                                                         WHERE
		                                                             ( CreateableObject_Checkbox__c IN : allBools ) AND
		                                                             ( SObjectParent__c = : parentSObjectType ) AND
		                                                             ( IsActive__c IN : allActiveBools )];

		// TODO fix ordering på name Activity_Timeline_Child__r.SObjectName__c and CreatableText

		if ( sObjectsToQuery.isEmpty() ) { throw new AuraException( Label.ActTime_NotConfugred ); }
		else {

			List<TAG_ActivityTimelineParent__mdt> sObjectsToUse = new List<TAG_ActivityTimelineParent__mdt>();
			for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQuery ) {
				if ( createable && TAG_ActivityTimelineHelper.isCreateable( mdt.Activity_Timeline_Child__r.SObjectName__c ) ) {
					sObjectsToUse.add( mdt );
				} else if ( !createable && TAG_ActivityTimelineHelper.isAccessible( mdt.Activity_Timeline_Child__r.SObjectName__c ) ) {
					sObjectsToUse.add( mdt );
				}
			}

			return sObjectsToUse;
		}
	}

	public static String getMonth( Integer monthNo ) {
		return IS_NORWEGIAN ? MONTH_NAME[monthNo] : MONTH_NAME_EN[monthNo];
	}

	public static List<TAG_ActivityTimelineModel> getOverdueOnly( List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery, String recordId ) {

		Map<String, TAG_ActivityTimelineParent__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig( sObjectsToQuery );
		sObjectsToQuery = new List<TAG_ActivityTimelineParent__mdt> { sObjectsToQueryMap.get( 'Task' ) };

		List<String>                    query =          TAG_ActivityTimelineHelper.createSoqlQueries( sObjectsToQuery, recordId, null );
		List<SObject>                   sObjects =       TAG_ActivityTimelineHelper.getSObjectsFromQueries( query );
		List<TAG_ActivityTimelineModel> data =           TAG_ActivityTimelineHelper.createActivityTimelineData( sObjectsToQuery, sObjects );

		data.sort();

		return data;
	}

	public static List<TAG_ActivityTimelineModel> getUpcomingOnly( List<TAG_ActivityTimelineModel> models ) {

		List<TAG_ActivityTimelineModel> tmpModels = new List<TAG_ActivityTimelineModel>();
		for ( TAG_ActivityTimelineModel model : models ) {

			Datetime d = model.config.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c ? System.today() : System.now();
			if ( model.record.dateValueDb >= d ) {
				tmpModels.add( model );
			}
		}

		return tmpModels;
	}

	public static List<TAG_ActivityTimelineModelList> getRecordsDividedIntoMonths( List<TAG_ActivityTimelineModel> data ) {

		Map<String, List<TAG_ActivityTimelineModel> > modelsSeparatedByMonth = new Map<String, List<TAG_ActivityTimelineModel> > ();

		for ( TAG_ActivityTimelineModel model : data ) {

			Datetime d = model.config.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c ? System.today() : System.now();

			if ( model.record.dateValueDb < d ) {
				String key = model.record.dateValueDb.month() + '' + model.record.dateValueDb.year();
				if ( modelsSeparatedByMonth.containsKey( key ) ) {
					modelsSeparatedByMonth.get( key ).add( model );
				} else {
					modelsSeparatedByMonth.put( key, new List<TAG_ActivityTimelineModel> { model } );
				}
			}
		}
		// TODO add missing months
		List<TAG_ActivityTimelineModelList> results = new List<TAG_ActivityTimelineModelList>();

		for ( String key : modelsSeparatedByMonth.keySet() ) {
			Datetime d = modelsSeparatedByMonth.get( key )[0].record.dateValueDb;
			String name = getMonth( d.month() ) + ' ' + d.year();
			results.add( new TAG_ActivityTimelineModelList( key, name, modelsSeparatedByMonth.get( key ), false, true ) );
		}

		return results;
	}

	public static Map<String, Id> getRecordTypes( List<TAG_ActivityTimelineParent__mdt> data ) {

		Set<String> recordTypeNames = new Set<String>();

		for ( TAG_ActivityTimelineParent__mdt mdt : data ) {
			if ( mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c != null ) {
				recordTypeNames.add( mdt.Activity_Timeline_Child__r.CreateableObject_RecordType__c );
			}
		}

		List<RecordType> recordTypes = [SELECT Id, Name, SobjectType FROM RecordType WHERE DeveloperName IN : recordTypeNames];
		Map<String, Id> recordTypeMap = new Map<String, Id>();
		for ( RecordType rt : recordTypes ) {
			recordTypeMap.put( rt.SobjectType + rt.Name, rt.Id );
		}

		return recordTypeMap;
	}



	public static List<String> createSoqlQueries( List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery, String recordId, Integer amountOfMonths ) {

		Set<String> queriedSobjects = new Set<String>();
		List<String> queries = new List<String>();

		for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQuery ) {

			String extraParameter = getExtraParameter( mdt, amountOfMonths, false );
			String extraField = mdt.Activity_Timeline_Child__r.SObjectName__c == 'Event' ? ',ActivityDateTime,IsAllDayEvent,DurationInMinutes' :
			                    mdt.Activity_Timeline_Child__r.SObjectName__c == 'Task' ? ',CreatedDate' : '';

			String fieldsToQuery = getFieldsToQueryFromMdt( sObjectsToQuery, mdt );

			if ( !queriedSobjects.contains( mdt.Activity_Timeline_Child__r.SObjectName__c ) ) {
				queries.add( getQuery( mdt, recordId, extraParameter, extraField, fieldsToQuery ) );
				queriedSobjects.add( mdt.Activity_Timeline_Child__r.SObjectName__c );

				if ( mdt.Activity_Timeline_Child__r.SObjectName__c == 'Task' ) {
					String dateLessParameter = getExtraParameter( mdt, amountOfMonths, true );
					queries.add( getQuery( mdt, recordId, dateLessParameter, extraField, fieldsToQuery ) );
				}
			}
		}

		return queries;
	}

	public static String getExtraParameter( TAG_ActivityTimelineParent__mdt mdt, Integer amountOfMonths, Boolean findDateless ) {

		Boolean isDate = findDateless ? false : mdt.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c;

		String now = '' + ( isDate ? System.today() : System.now() );
		if ( isDate ) { now = now.replaceAll( ' 00:00:00', '' ); }
		else { now = now.replaceAll( ' ', 'T' ) + 'Z'; }

		String dateField = findDateless ? 'CreatedDate' : mdt.Activity_Timeline_Child__r.SObjectDateField__c;

		if ( amountOfMonths != null ) {
			return '(' +
			       dateField + ' = LAST_N_MONTHS:' + (amountOfMonths - 1) + ' OR ' +
			       dateField + ' = THIS_MONTH OR ' +
			       dateField + ' > ' + now +
			       ')' + (findDateless ? ' AND ' + mdt.Activity_Timeline_Child__r.SObjectDateField__c + ' = null' : '');
		} else { // get overdue only, as no month is specified
			return '' + dateField + ' < ' + now +
			       '  AND Status != \'Completed\'' +
			       (findDateless ? ' AND ' + mdt.Activity_Timeline_Child__r.SObjectDateField__c + ' = null' : '');
		}
	}

	public static String getQuery( TAG_ActivityTimelineParent__mdt mdt, String recordId, String extraParameter, String extraField, String fieldsToQuery ) {
		return 'SELECT Id,' + fieldsToQuery + extraField +

		       ' FROM ' + mdt.Activity_Timeline_Child__r.SObjectName__c +

		       ' WHERE ' + mdt.SObjectRelationshipField__c + ' = \'' + recordId + '\'' +
		       ' AND ' + extraParameter +

		       ' ORDER BY ' + mdt.Activity_Timeline_Child__r.SObjectDateField__c;
	}

	public static String getFieldsToQueryFromMdt( List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery, TAG_ActivityTimelineParent__mdt currentObject ) {

		Set<String> fieldsToQuery = new Set<String>();
		for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQuery ) {
			if ( mdt.Activity_Timeline_Child__r.SObjectName__c == currentObject.Activity_Timeline_Child__r.SObjectName__c ) {

				for ( String mdtField : CHILD_FIELDS_TO_QUERY ) {

					String field = '';
					if ( mdtField.contains( '__r' ) ) {
						field =  (String) mdt.getSObject( mdtField.split( '\\.' )[0] ).get( mdtField.split( '\\.' )[1] );
					} else {
						field =  (String) mdt.get( mdtField );
					}
					if ( field != null ) {
						fieldsToQuery.add( field );
					}
				}
			}
		}

		if ( currentObject.Activity_Timeline_Child__r.SObjectName__c == 'Task' ) {
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

	public static List<TAG_ActivityTimelineModel> createActivityTimelineData( List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery, List<SObject> sObjects ) {

		List<TAG_ActivityTimelineModel> data = new List<TAG_ActivityTimelineModel>();
		Map<String, TAG_ActivityTimelineParent__mdt> sObjectsToQueryMap = getMapOfActivityTimelineConfig( sObjectsToQuery );

		for ( SObject sObj : sObjects ) {
			String childSObjectKind = getSOjectTypeFromRecordId( (Id) sObj.get( 'Id' ) );
			String childSObjectType = '';
			for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQueryMap.values() ) {
				if ( mdt.Activity_Timeline_Child__r.SObjectName__c == childSObjectKind ) {
					if ( mdt.Activity_Timeline_Child__r.SObjectTypeField__c != null ) {
						String type = (String) sObj.get( mdt.Activity_Timeline_Child__r.SObjectTypeField__c );
						if ( type != null ) {
							childSObjectType = type;
							break;
						}
					}
				}
			}

			TAG_ActivityTimelineParent__mdt mdt = sObjectsToQueryMap.get( childSObjectKind + childSObjectType );
			if ( mdt == null ) { mdt = sObjectsToQueryMap.get( childSObjectKind ); }
			if ( mdt != null ) {
				data.add( new TAG_ActivityTimelineModel( mdt, sObj, USER.LanguageLocaleKey ) );
			}
		}

		return data;
	}

	public static List<TAG_ActivityTimelineModel> getOwnerAndContactNames( List<TAG_ActivityTimelineModel> models ) {

		Set<Id> ownerIds = new Set<Id>();
		Set<Id> contactIds = new Set<Id>();

		for ( TAG_ActivityTimelineModel model : models ) {
			if ( model.record.assigneeId != null ) { ownerIds.add( model.record.assigneeId ); }
			if ( model.record.relatedUserId != null ) { contactIds.add( model.record.relatedUserId ); }
		}

		Map<Id, String> ownerNames = getOwnerName( ownerIds );
		Map<Id, String> contactNames = getContactName( contactIds );

		for ( TAG_ActivityTimelineModel model : models ) {

			if ( model.record.dateValueDb < DateTime.now() && !model.record.overdue ) {
				model.record.subtitle = USER.LanguageLocaleKey == 'Norsk' ? model.config.Activity_Timeline_Child__r.SubtitlePastNorwegian__c : model.config.Activity_Timeline_Child__r.SubtitlePastEnglish__c;
			} else {
				model.record.subtitle = USER.LanguageLocaleKey == 'Norsk' ? model.config.Activity_Timeline_Child__r.SubtitleFutureNorwegian__c : model.config.Activity_Timeline_Child__r.SubtitleFutureEnglish__c;
			}

			if ( model.record.assigneeId != null ) {
				if ( ownerNames.containsKey( model.record.assigneeId ) ) {
					model.record.assignee = ownerNames.get( model.record.assigneeId );
					if ( model.record.assigneeId == UserInfo.getUserId() ) {
						model.record.assigneeId = null;
					}
				}
			}

			if ( model.record.relatedUserId != null ) {
				if ( contactNames.containsKey( model.record.relatedUserId ) ) {
					model.record.relatedUser = contactNames.get( model.record.relatedUserId );
					if ( model.record.relatedUser != null ) {
						model.record.subtitle += USER.LanguageLocaleKey == 'Norsk' ? ' ' + returnValueIfNotNull( model.config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionNor__c ) : ' ' + returnValueIfNotNull( model.config.Activity_Timeline_Child__r.SubtitleRelatedUserPrepositionEng__c );
					}
				}
			} else if ( model.record.sObjectKind == 'Task' && model.record.type == 'Call' ) {
				model.record.relatedUser = Label.ActTime_Unknown.toLowerCase();
			}
		}

		return models;
	}

	public static String returnValueIfNotNull( String input ) {
		return input != null ? input : '';
	}

	public static Map<Id, String> getOwnerName( Set<Id> ownerIds ) {

		Map<Id, String> results = new Map<Id, String>();
		Map<Id, User> users = new Map<Id, User> ( [SELECT Name FROM User WHERE Id IN: ownerIds ] );

		for ( Id ownerId : ownerIds ) {
			if ( ownerId == UserInfo.getUserId() ) {
				results.put( ownerId, Label.ActTime_You );
			} else if ( users.containsKey( ownerId ) ) {
				results.put( ownerId, users.get( ownerId ).Name );
			}
		}

		return results;
	}

	public static Map<Id, String> getContactName( Set<Id> contactIds ) {

		Map<Id, String> results = new Map<Id, String>();
		Map<Id, Contact> contacts = new Map<Id, Contact> ( [SELECT Name FROM Contact WHERE Id IN: contactIds ] );

		for ( Id contactId : contactIds ) {
			if ( contacts.containsKey( contactId ) ) {
				results.put( contactId, contacts.get( contactId ).Name );
			}
		}

		return results;
	}

	public static List<TAG_ActivityTimelineModelList> removeConfig( List<TAG_ActivityTimelineModelList> data ) {
		for ( TAG_ActivityTimelineModelList d : data ) {
			for ( TAG_ActivityTimelineModel model : d.models ) {
				model.config = null;
			}
		}

		return data;
	}

	public static Map<String, TAG_ActivityTimelineParent__mdt> getMapOfActivityTimelineConfig( List<TAG_ActivityTimelineParent__mdt> sObjectsToQuery ) {
		Map<String, TAG_ActivityTimelineParent__mdt> sObjectsToQueryMap = new Map<String, TAG_ActivityTimelineParent__mdt>();

		for ( TAG_ActivityTimelineParent__mdt mdt : sObjectsToQuery ) {
			String mdtType = mdt.Activity_Timeline_Child__r.SObjectTypeValue__c != null && mdt.Activity_Timeline_Child__r.SObjectTypeValue__c != 'null' ? mdt.Activity_Timeline_Child__r.SObjectTypeValue__c : '';
			if ( mdtType.contains( ';' ) ) {
				List<String> typeList = mdtType.split( ';' );
				for ( String type : typeList ) {
					sObjectsToQueryMap.put( mdt.Activity_Timeline_Child__r.SObjectName__c + type, mdt );
				}
			} else {
				sObjectsToQueryMap.put( mdt.Activity_Timeline_Child__r.SObjectName__c + mdtType, mdt );
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
