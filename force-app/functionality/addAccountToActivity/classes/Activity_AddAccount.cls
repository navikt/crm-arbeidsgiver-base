global class Activity_AddAccount extends MyTriggers {

	global override void onBeforeUpdate( Map<Id, SObject> triggerOldMap ) {
		// TODO check if user have access
		List<SObject> sObjects = Activity_AddAccountHelper.getActivityWithChangedWhatId( triggerOldMap, ( List<SObject> ) records );
		if ( sObjects.size() > 0 ) {
			Activity_AddAccountHelper.addAccount( sObjects, false );
		}
	}

	global override void onAfterInsert() {
		List<SObject> sObjects = Activity_AddAccountHelper.addAccount( ( List<SObject> ) records, true );
		update sObjects;
	}
}