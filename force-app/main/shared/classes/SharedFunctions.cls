public with sharing class SharedFunctions {


	public static Map<String, Account> fetchAccounts( List<String> organisationNumbers ) {

		List<Account> accounts = [SELECT Id, INT_OrganizationNumber__c, INT_MunicipalityNumber__c FROM Account

		                          WHERE
		                              ( INT_OrganizationNumber__c IN : organisationNumbers ) AND
		                              ( INT_OrganizationNumber__c != null ) AND
		                              ( IsPersonAccount = false )];

		Map<String, Account> accountMap = new Map<String, Account>();
		for ( Account acc : accounts ) {
			accountMap.put( acc.INT_OrganizationNumber__c, acc );
		}

		return accountMap;
	}

	public static Map<String, Contact> fetchOrCreateContact( List<SharedFunctions_Helper.ContactWrapper> wrapperList, Map<String, Account> accountMap ) {

		// get existing contacts based on email address on Contact.Email or Contact.InvalidEmail__c
		List<Contact> existingContacts = SharedFunctions_Helper.getExistingContacts( wrapperList );

		SharedFunctions_Helper.addNewSourceToExistingContacts( wrapperList, existingContacts );

		// map existing conacts to a new account (if user sent a request on behalf on a another account but same email)
		SharedFunctions_Helper.mapUnmappedContacts( wrapperList, existingContacts, accountMap );

		// create a map from the existing conacts
		Map<String, Contact> contactMap = SharedFunctions_Helper.createContactMapWithEmailAsKey( existingContacts );

		// will create contacts that don't already exists and add them to contactMap
		SharedFunctions_Helper.createRemainingContacts( wrapperList, accountMap, contactMap );

		return contactMap;
	}
}