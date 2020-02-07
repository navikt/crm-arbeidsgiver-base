@isTest
private without sharing class TAG_TestDataFactoryTest {

	@isTest
	private static void testCreateStandardUser() {

		Integer beforeUser = [SELECT Id FROM User].size();

		Test.StartTest();
		TAG_TestDataFactory.createStandardUser();
		Test.StopTest();

		Integer afterUser = [SELECT Id FROM User].size();

		System.assertEquals( 1, afterUser - beforeUser, 'New user should have been created' );
	}

	@isTest
	private static void testGetOwnerForAccounts() {

		Integer beforeUser = [SELECT Id FROM User].size();

		Test.StartTest();
		TAG_TestDataFactory.getOwnerForAccounts();
		Test.StopTest();

		Integer afterUser = [SELECT Id FROM User].size();

		System.assertEquals( 1, afterUser - beforeUser, 'New user should have been created' );
	}

	@isTest
	private static void testCreateAccounts() {

		Integer beforeAccount = [SELECT Id FROM Account].size();
		Integer amount = 4;
		Test.StartTest();
		TAG_TestDataFactory.createAccounts( amount );
		Test.StopTest();

		Integer afterAccount = [SELECT Id FROM Account].size();

		System.assertEquals( amount, afterAccount - beforeAccount, 'New user should have been created' );
	}
}