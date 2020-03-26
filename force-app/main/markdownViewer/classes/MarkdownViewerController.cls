public with sharing class MarkdownViewerController {

	@AuraEnabled(cacheable = true)
	public static String getData( String recordId, String objectApiName, String fieldName ) {


		if ( !isAccessible( objectApiName, fieldName ) ) { return null; }

		String query = 'SELECT ' + fieldName + ' FROM ' + objectApiName + ' WHERE Id = : recordId LIMIT 1';
		List<SObject> results = Database.query( query );
		System.debug( '(String) results[0].get( fieldName ): ' + (String) results[0].get( fieldName ) );

		return (String) results[0].get( fieldName );
	}

	public static Boolean isAccessible( String sObjectType, String fieldName ) {
		SObjectType schemaType = Schema.getGlobalDescribe().get( sObjectType );
		Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
		DescribeFieldResult fieldDescribe = fields.get( fieldName ).getDescribe();

		return fieldDescribe.isAccessible();
	}
}