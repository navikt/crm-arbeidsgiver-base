global class Contact_InvalidEmailRemoval extends MyTriggers {

	global override void onBeforeUpdate( Map<Id, SObject> triggerOldMap ) {
		removeInvalidEmail( (List<Contact>) records );
	}

	global override void onBeforeInsert() {
		removeInvalidEmail( (List<Contact>) records );
	}

	public static void removeInvalidEmail( List<Contact> contacts ) {
		for ( Contact con : contacts ) {
			if ( con.Email != null && con.InvalidEmail__c != null ) {
				con.InvalidEmail__c = null;
			}
		}
	}
}
