public with sharing class MarkdownViewerController {

	@AuraEnabled(cacheable = true)
	public static String getData( String recordId, String objectApiName, String fieldName ) {


		if ( !AccessControlValidator.fieldIsAccessible( objectApiName, fieldName ) ) { return null; }

		String query = 'SELECT ' + fieldName + ' FROM ' + objectApiName + ' WHERE Id = : recordId LIMIT 1';
		List<SObject> results = Database.query( query );
		System.debug( '(String) results[0].get( fieldName ): ' + (String) results[0].get( fieldName ) );

		return (String) results[0].get( fieldName );
	}
}