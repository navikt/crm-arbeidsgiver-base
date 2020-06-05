global class Activity_AddAccount extends MyTriggers {

	global override void onBeforeUpdate( Map<Id, SObject> triggerOldMap ) {
		List<SObject>  sObjects = getActivityWithChangedWhatId( triggerOldMap, ( List<SObject> ) records );
		addAccount( sObjects );
	}

	global override void onAfterInsert() {
		List<SObject> sObjects = addAccount( ( List<SObject> ) records );
		// update sObjects;
	}

	public static List<SObject> addAccount( List<SObject> sObjects ) {

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
