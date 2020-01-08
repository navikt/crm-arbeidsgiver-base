public with sharing class TAG_ActivityTimelineDataProvider {

	private static final List<String> FIELDS_TO_QUERY = new List<String> { 'SObjectDateField__c', 'SObjectTitle__c' };

	@AuraEnabled(cacheable = false)
	public static List<SObject> getTimelineItemData( String recordId ) {

		if ( recordId == null ) { throw new AuraException( 'Error. Invalid record ID.' ); }
		String parentSObjectType = getSOjectTypeFromRecordId( recordId );
		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = getSObjectsToQuery( parentSObjectType );
		List<String> queries = createSoqlQueries( sObjectsToQuery );
		List<SObject> sObjects = getSObjectsFromQueries( queries, recordId );

		return sObjects;
	}

	public static String getSOjectTypeFromRecordId( String recordId ) {

		Id i = (Id) recordId;

		return String.valueOf( i.getSobjectType() );

	}

	public static List<TAG_ActivityTimeline__mdt> getSObjectsToQuery( String parentSObjectType ) {

		List<TAG_ActivityTimeline__mdt> sObjectsToQuery = [SELECT Id,
		                                                   Color__c, Icon__c,
		                                                   SObjectChild__c, SObjectParent__c,
		                                                   SObjectDateField__c,  SObjectTitle__c,
		                                                   SObjectRelationshipField__c
		                                                   FROM TAG_ActivityTimeline__mdt WHERE SObjectParent__c = : parentSObjectType];

		if ( sObjectsToQuery.isEmpty() ) {
			throw new AuraException( 'Error. Not configured for this SObject type.' );
		} else {
			return sObjectsToQuery;
		}
	}

	public static List<String> createSoqlQueries( List<TAG_ActivityTimeline__mdt> sObjectsToQuery ) {

		List<String> queries = new List<String>();

		for ( TAG_ActivityTimeline__mdt mdt : sObjectsToQuery ) {

			String fieldsToQuery = getFieldsToQueryFromMdt( mdt, FIELDS_TO_QUERY );
			String query = 'SELECT Id, ' + fieldsToQuery + ' FROM ' + mdt.SObjectChild__c + ' WHERE ' + mdt.SObjectRelationshipField__c + ' =: recordId';
			queries.add( query );
		}

		return queries;
	}

	public static String getFieldsToQueryFromMdt( TAG_ActivityTimeline__mdt mdt, List<String> mdtFieldsToQuery ) {

		String fieldsToQuery = '';
		for ( String mdtField : mdtFieldsToQuery ) {
			String field = (String) mdt.get( mdtField );
			if ( field != null ) {
				fieldsToQuery +=  field + ',';
			}
		}

		return fieldsToQuery.removeEnd( ',' );
	}

	public static List<SObject> getSObjectsFromQueries( List<String> queries, String recordId ) {

		List<SObject> sObjects = new List<SObject>();

		for ( String query : queries ) {
			List<SObject> sObjs = Database.query( query );
			sObjects.addAll( sObjs );
		}

		return sObjects;
	}

}
