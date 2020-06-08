public with sharing class Activity_AddAccountHelper {
	public static List<SObject> addAccount( List<SObject> sObjects ) {

		// String parentSObjectType = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( recordId );
		List<Id> whatIds = new List<Id>();

		for ( SObject sObj : sObjects ) {
			if ( !whatIds.contains( sObj.get( 'WhatId' ) ) ) {
				whatIds.add( sObj.get( 'WhatId' ) );
			}
		}

		whatIds.sort();



		return sObjects;
	}

	public static Map<String, Set<Id> > getIdsSeparatedByObject( List<Id> whatIds ) {

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
