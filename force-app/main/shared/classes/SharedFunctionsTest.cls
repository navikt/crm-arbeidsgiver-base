@isTest
private without sharing class SharedFunctionsTest {

	@testSetup
	private static void setup() {

	}

	@isTest
	private static void testFetchAccounts() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Account acc2 = new Account( Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777' );
		insert acc2;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'tore.toresen@example.com', AccountId = acc.Id );
		insert con;

		Test.StartTest();
		Map<String, Account> result = SharedFunctions.fetchAccounts( new List<String> { acc.INT_OrganizationNumber__c, acc2.INT_OrganizationNumber__c } );
		Test.StopTest();

		System.assertEquals( acc.Id, result.get( acc.INT_OrganizationNumber__c ).Id, 'Should be same account' );
		System.assertEquals( acc2.Id, result.get( acc2.INT_OrganizationNumber__c ).Id, 'Should be same account' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 1, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_create() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test@test.com';
		wrapper.companyNumber = '99999999';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( acc.Id, result.get( 'test@test.com' ).AccountId, 'Should be same account' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 1, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_emptyEmail() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Account acc2 = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '677777' );
		insert acc2;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = '';
		wrapper.companyNumber = '677777';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		List<Contact> contacts = [SELECT Id FROM Contact];
		System.assertEquals( 1, contacts.size(), 'Before, only 1 contact' );

		Test.StartTest();
		SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		contacts = [SELECT Id FROM Contact];
		System.assertEquals( 2, contacts.size(), 'After, 2 contacts despite empty email' );
	}

	@isTest
	private static void testFetchOrCreateContact_invalidEmail() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test @domain.com';
		wrapper.companyNumber = '99999999';
		wrapperList.add( wrapper );

		SharedFunctions_Helper.ContactWrapper wrapper2 = new SharedFunctions_Helper.ContactWrapper();
		wrapper2.firstName = 'test';
		wrapper2.lastName = 'etternavn';
		wrapper2.phone = '90080900';
		wrapper2.email = 'testÆØÅ@domain.com';
		wrapper2.companyNumber = '99999999';
		wrapperList.add( wrapper2 );

		SharedFunctions_Helper.ContactWrapper wrapper3 = new SharedFunctions_Helper.ContactWrapper();
		wrapper3.firstName = 'test';
		wrapper3.lastName = 'etternavn';
		wrapper3.phone = '90080900';
		wrapper3.email = 'test@domaincom';
		wrapper3.companyNumber = '99999999';
		wrapperList.add( wrapper3 );

		SharedFunctions_Helper.ContactWrapper wrapper4 = new SharedFunctions_Helper.ContactWrapper();
		wrapper4.firstName = 'test';
		wrapper4.lastName = 'etternavn';
		wrapper4.phone = '90080900';
		wrapper4.email = 'te@st@domain.com';
		wrapper4.companyNumber = '99999999';
		wrapperList.add( wrapper4 );

		SharedFunctions_Helper.ContactWrapper wrapper5 = new SharedFunctions_Helper.ContactWrapper();
		wrapper5.firstName = 'test';
		wrapper5.lastName = 'etternavn';
		wrapper5.phone = '90080900';
		wrapper5.email = 'test@domain';
		wrapper5.companyNumber = '99999999';
		wrapperList.add( wrapper5 );

		SharedFunctions_Helper.ContactWrapper wrapper6 = new SharedFunctions_Helper.ContactWrapper();
		wrapper6.firstName = 'test';
		wrapper6.lastName = 'etternavn';
		wrapper6.phone = '90080900';
		wrapper6.email = 'test£@domain.com';
		wrapper6.companyNumber = '99999999';
		wrapperList.add( wrapper6 );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		List<Contact> contacts = [SELECT Id FROM Contact];
		System.assertEquals( 0, contacts.size(), 'Before, only 1 contact' );

		Test.StartTest();
		SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		contacts = [SELECT Id, InvalidEmail__c, Email FROM Contact];
		System.assertEquals( 6, contacts.size(), 'After, 6 contacts despite invalid email' );

		for ( Contact c : contacts ) {
			System.assertEquals( null, c.Email, 'Email should be null, as the emailed added is invalid' );
			System.assertNotEquals( null, c.InvalidEmail__c, 'InvalidEmail__c should not be null, as the email added is invalid' );
		}
	}

	@isTest
	private static void testFetchOrCreateContact_invalidEmailExisting_CreateNewWithInvalidEmail() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'Toråsen', InvalidEmail__c = 'test @domain.com', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test @domain.com';
		wrapper.companyNumber = '99999999';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		List<Contact> contacts = [SELECT Id FROM Contact];
		System.assertEquals( 1, contacts.size(), 'Before, only 1 contact' );

		Test.StartTest();
		SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		contacts = [SELECT Id, InvalidEmail__c, Email FROM Contact];
		System.assertEquals( 1, contacts.size(), 'After, still only one contact despite invalid email' );

		for ( Contact c : contacts ) {
			System.assertEquals( null, c.Email, 'Email should be null, as the emailed added is invalid' );
			System.assertEquals( 'test @domain.com', c.InvalidEmail__c, 'InvalidEmail__c should not be null, as the email added is invalid' );
			System.assertEquals( con.Id, c.Id, 'Same contact' );
		}

	}


	@isTest
	private static void testFetchOrCreateContact_existingContact() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test@test.com', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test@test.com';
		wrapper.companyNumber = '99999999';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( con.Id, result.get( 'test@test.com' ).Id, 'Should be same existing contact' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 1, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_existingContactOnAnotherAccount() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Account acc2 = new Account( Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777' );
		insert acc2;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test@test.com', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test@test.com';
		wrapper.companyNumber = '77777777';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( con.Id, result.get( 'test@test.com' ).Id, 'Should be same existing contact' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 2, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_existingContactOnAnotherAccount_sameUserMultipleInsertions() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Account acc2 = new Account( Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777' );
		insert acc2;

		Account acc3 = new Account( Name = 'Test Employer 2', INT_OrganizationNumber__c = '4444' );
		insert acc3;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test@test.com', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test@test.com';
		wrapper.companyNumber = '77777777';
		wrapperList.add( wrapper );


		SharedFunctions_Helper.ContactWrapper wrapper2 = new SharedFunctions_Helper.ContactWrapper();
		wrapper2.firstName = 'test';
		wrapper2.lastName = 'etternavn';
		wrapper2.phone = '90080900';
		wrapper2.email = 'test@test.com';
		wrapper2.companyNumber = '4444';
		wrapperList.add( wrapper2 );


		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber, wrapper2.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( con.Id, result.get( 'test@test.com' ).Id, 'Should be same existing contact' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 3, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_existingContactOnAnotherAccount_multipleUsers() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '77777777' );
		insert acc;

		Account acc2 = new Account( Name = 'Test Employer 2', INT_OrganizationNumber__c = '4444' );
		insert acc2;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test@test.com', AccountId = acc.Id );
		insert con;

		Contact con2 = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test_new@test.com', AccountId = acc2.Id );
		insert con2;

		Account acc3 = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '9999999' );
		insert acc3;

		Account acc4 = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '3333' );
		insert acc4;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'test@test.com';
		wrapper.companyNumber = '9999999';
		wrapperList.add( wrapper );


		SharedFunctions_Helper.ContactWrapper wrapper2 = new SharedFunctions_Helper.ContactWrapper();
		wrapper2.firstName = 'test2';
		wrapper2.lastName = 'etternavn2';
		wrapper2.phone = '34430400';
		wrapper2.email = 'test_new@test.com';
		wrapper2.companyNumber = '3333';
		wrapperList.add( wrapper2 );


		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber, wrapper2.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( con.Id, result.get( 'test@test.com' ).Id, 'Should be same existing contact' );

		Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
		System.assertEquals( 4, contactRelationships, 'Should have added the contact to the new accounts as a relationship' );
	}

	@isTest
	private static void testFetchOrCreateContact_uppcaseEmail() {

		Account acc = new Account( Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999' );
		insert acc;

		Contact con = new Contact( TAG_Informed__c = true, LastName = 'test', FirstName = 'test', Email = 'test@test.com', AccountId = acc.Id );
		insert con;

		List<SharedFunctions_Helper.ContactWrapper> wrapperList = new List<SharedFunctions_Helper.ContactWrapper>();
		SharedFunctions_Helper.ContactWrapper wrapper = new SharedFunctions_Helper.ContactWrapper();
		wrapper.firstName = 'test';
		wrapper.lastName = 'etternavn';
		wrapper.phone = '90080900';
		wrapper.email = 'Test@test.com'; // ! upper case T
		wrapper.companyNumber = '77777777';
		wrapperList.add( wrapper );

		Map<String, Account> accountMap = SharedFunctions.fetchAccounts( new List<String> { wrapper.companyNumber } );

		Test.StartTest();
		Map<String, Contact> result = SharedFunctions.fetchOrCreateContact( wrapperList, accountMap );
		Test.StopTest();

		System.assertEquals( con.Id, result.get( 'test@test.com' ).Id, 'Should be same existing contact' );

	}
}