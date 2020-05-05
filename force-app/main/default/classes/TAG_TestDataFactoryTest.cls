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

	@IsTest
	private static void getCustomOpportunities() {
		Integer amount = 4;
		Test.StartTest();
		TAG_TestDataFactory.getCustomOpportunities( 4, true );
		Test.StopTest();

		Integer afterOpportunity = [SELECT Id FROM CustomOpportunity__c].size();

		System.assertEquals( amount, afterOpportunity, 'New opportunities should have been created' );
	}

	@IsTest
	private static void testGetTemporaryLayoffs() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		update acc;
		Integer amount = 4;
		Test.StartTest();
		TAG_TestDataFactory.getTemporaryLayoffs( 4, acc, true );
		Test.StopTest();

		Integer afterLayoffs = [SELECT Id FROM TemporaryLayoff__c].size();

		System.assertEquals( amount, afterLayoffs, 'New layoffs should have been created' );
	}
}