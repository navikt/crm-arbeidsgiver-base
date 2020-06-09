public with sharing class Activity_AddAccountHelper {
	public static List<SObject> addAccount( List<SObject> sObjects ) {

		Set<Id> whatIds = new Set<Id>();

		for ( SObject sObj : sObjects ) {
			whatIds.add( (Id) sObj.get( 'WhatId' ) );
		}

		List<Id> whatIdList = new List<Id>();
		whatIdList.addAll( whatIds );
		whatIdList.sort();
		whatIds = new Set<Id>( whatIdList );

		Map<String, Set<Id> > idsSeparatedBysObject = getIdsSeparatedBySObject( whatIds );
		Map<String, List<SObject> > sObjectsSeparatedBySObject = getSObjectsSeparatedBySObject( idsSeparatedBysObject );
		sObjects = addAccountToActivity( sObjects, sObjectsSeparatedBySObject );

		return sObjects;
	}

	public static Map<String, Set<Id> > getIdsSeparatedBySObject( Set<Id> whatIds ) {

		Map<String, Set<Id> > idsSeparatedBysObject = new Map<String, Set<Id> >();

		for ( Id i : whatIds ) {

			String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( i );

			if ( idsSeparatedBysObject.containsKey( parentSObjectType ) ) {
				idsSeparatedBysObject.get( parentSObjectType ).add( i );
			} else {
				idsSeparatedBysObject.put( parentSObjectType, new Set<Id> { i } );
			}
		}

		return idsSeparatedBysObject;
	}

	public static Map<String, List<SObject> > getSObjectsSeparatedBySObject( Map<String, Set<Id> > idsSeparatedBysObject ) {

		List<Activity_Account_Map__mdt> activityAccountMapping = [SELECT Id, SObject_API_Field_Name__c, SObject_API_Name__c FROM Activity_Account_Map__mdt];
		Map<String, String> accountMap = new Map<String, String>();
		for ( Activity_Account_Map__mdt mdt : activityAccountMapping ) {
			accountMap.put( mdt.SObject_API_Name__c.toLowerCase(), mdt.SObject_API_Field_Name__c );
		} // TODO its own function

		Map<String, List<SObject> > sObjectsSeparatedBySObject = new Map<String, List<SObject> >();

		List<String> queries = new List<String>();

		for ( String sObjectName : idsSeparatedBysObject.keySet() ) {

			String sObjectFieldName = accountMap.get( sObjectName.toLowerCase() );

			if ( sObjectFieldName == null ) { continue; } // skip iteration

			String ids = '(\'' + String.join( (Iterable<String>) idsSeparatedBysObject.get( sObjectName ), '\', \'' ) + '\')';
			String query = 'SELECT Id, ' + sObjectFieldName + ' FROM ' + sObjectName + ' WHERE Id IN ' + ids;
			System.debug( 'query: ' + query );
			List<SObject> sObjects = Database.query( query );
			sObjectsSeparatedBySObject.put( sObjectName, sObjects );
		}

		return sObjectsSeparatedBySObject;
	}

	public static List<SObject> addAccountToActivity( List<SObject> sObjects, Map<String, List<SObject> > sObjectsSeparatedBySObject ) {

		List<Activity_Account_Map__mdt> activityAccountMapping = [SELECT Id, SObject_API_Field_Name__c, SObject_API_Name__c FROM Activity_Account_Map__mdt];
		Map<String, String> accountMap = new Map<String, String>();
		for ( Activity_Account_Map__mdt mdt : activityAccountMapping ) {
			accountMap.put( mdt.SObject_API_Name__c.toLowerCase(), mdt.SObject_API_Field_Name__c );
		}

		for ( SObject childSObj : sObjects ) {

			String childSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( childSObj.Id );
			String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( (String) childSObj.get( 'WhatId' ) );

			if ( sObjectsSeparatedBySObject.containsKey( parentSObjectType ) ) {
				for ( SObject parentSObj : sObjectsSeparatedBySObject.get( parentSObjectType ) ) {
					if ( childSObj.get( 'WhatId' ) == parentSObj.Id ) {
						if ( childSObjectType == 'Task' ) {
							(Task) childSObj.Account__c = parentSObj.get( accountMap.get( parentSObjectType ) );
						} else if ( childSObjectType == 'Event' ) {
							(Event) childSObj.Account__c = parentSObj.get( accountMap.get( parentSObjectType ) );
						}
					}
				}
			}
		}

		return sObjects;
	}

	public static List<SObject> getActivityWithChangedWhatId( Map<Id, SObject> triggerOldMap, List<SObject> newRecords ) {

		List<SObject> sObjectsToAddAccount = new List<SObject>();

		for ( SObject sObj : newRecords ) {

			if ( sObj.get( 'WhatId' ) != triggerOldMap.get( sObj.Id ).get( 'WhatId' ) ) {
				sObjectsToAddAccount.add( sObj );
			}
		}

		return sObjectsToAddAccount;
	}
}
