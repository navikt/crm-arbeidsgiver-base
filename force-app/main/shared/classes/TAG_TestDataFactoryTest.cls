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

	@IsTest
	private static void testAssignPermissionSet() {
		Test.startTest();
		TAG_TestDataFactory.assignPermissionSet( 'testgfd899@nav.test', 'ManageAccounts' );
		Test.stopTest();

		List<User> users = [SELECT Id FROM User WHERE Username = 'testgfd899@nav.test'];
		System.assertEquals( 1, users.size(), 'User is not created' );
		List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = 'ManageAccounts'];
		System.assertEquals( 1, permissionSets.size(), 'Permission set is not created' );

		List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =:users[0].Id AND PermissionSetId =:permissionSets[0].Id];
		System.assertEquals( 1, PermissionSetAssignments.size(), 'Permission set is not assigned to new user' );
	}
}