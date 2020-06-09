global class Activity_AddAccountToEvent extends MyTriggers {

	global override void onBeforeUpdate( Map<Id, SObject> triggerOldMap ) {
		List<SObject>  sObjects = Activity_AddAccountHelper.getActivityWithChangedWhatId( triggerOldMap, ( List<SObject> ) records );
		Activity_AddAccountHelper.addAccount( sObjects, 'Event' );
	}

	global override void onAfterInsert() {
		// List<SObject> sObjects = Activity_AddAccountHelper.addAccount( ( List<SObject> ) records, 'Event' );
		// update sObjects;
	}


}
