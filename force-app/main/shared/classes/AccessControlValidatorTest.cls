@isTest
private without sharing class AccessControlValidatorTest {

	@testSetup
	private static void setup() {
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Arbeidsgiver_Base_Group' LIMIT 1];
		User u = TAG_TestDataFactory.createStandardUser();
		insert new PermissionSetAssignment( AssigneeId = U.id, PermissionSetId = ps.Id );
	}

	@isTest
	private static void testSObjectIsAccessible_anon() {

		Test.StartTest();
		Boolean result = AccessControlValidator.sObjectIsAccessible( 'TemporaryLayoff__c' );
		Test.StopTest();

		System.assert (result, 'Anonymous user should always have access');
	}

	@isTest
	private static void testSObjectIsAccessible_emptyUser() {

		User u = TAG_TestDataFactory.createStandardUser();
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.sObjectIsAccessible( 'TemporaryLayoff__c' );
		}
		Test.StopTest();

		System.assert (!result, 'Empty user user should NOT have access');
	}

	@isTest
	private static void testSObjectIsAccessible_emptyUserWithPermset() {

		User u = [SELECT Id FROM User WHERE LastName = 'Last UNIQUE NAME' LIMIT 1];
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.sObjectIsAccessible( 'TemporaryLayoff__c' );
		}
		Test.StopTest();

		System.assert (result, 'New user should have access');
	}

	@isTest
	private static void testSObjectIsCreateable_anon() {

		Test.StartTest();
		Boolean result = AccessControlValidator.sObjectIsCreateable( 'CustomOpportunity__c' );
		Test.StopTest();

		System.assert (result, 'Anonymous user should always have access');
	}

	@isTest
	private static void testSObjectIsCreateable_emptyUser() {

		User u = TAG_TestDataFactory.createStandardUser();
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.sObjectIsCreateable( 'CustomOpportunity__c' );
		}
		Test.StopTest();

		System.assert (!result, 'Empty user user should NOT have access');
	}

	@isTest
	private static void testSObjectIsCreateable_emptyUserWithPermset() {

		User u = [SELECT Id FROM User WHERE LastName = 'Last UNIQUE NAME' LIMIT 1];
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.sObjectIsCreateable( 'CustomOpportunity__c' );
		}
		Test.StopTest();

		System.assert (result, 'New user should have access');
	}

	@isTest
	private static void testFieldIsAccessible_anon() {

		Test.StartTest();
		Boolean result = AccessControlValidator.fieldIsAccessible( 'Task', 'RelatedToAccount__c' );
		Test.StopTest();

		System.assert (result, 'Anonymous user should always have access');
	}

	@isTest
	private static void testFieldIsAccessible_emptyUser() {

		User u = TAG_TestDataFactory.createStandardUser();
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.fieldIsAccessible( 'Task', 'RelatedToAccount__c' );
		}
		Test.StopTest();

		System.assert (!result, 'Empty user user should NOT have access');
	}

	@isTest
	private static void testFieldIsAccessible_emptyUserWithPermset() {

		User u = [SELECT Id FROM User WHERE LastName = 'Last UNIQUE NAME' LIMIT 1];
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.fieldIsAccessible( 'Task', 'RelatedToAccount__c' );
		}
		Test.StopTest();

		System.assert (result, 'New user should have access');
	}

	@isTest
	private static void testFieldIsCreateable_anon() {

		Test.StartTest();
		Boolean result = AccessControlValidator.fieldIsCreateable( 'Task', 'RelatedToAccount__c' );
		Test.StopTest();

		System.assert (result, 'Anonymous user should always have access');
	}

	@isTest
	private static void testFieldIsCreateable_emptyUser() {

		User u = TAG_TestDataFactory.createStandardUser();
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.fieldIsCreateable( 'Task', 'RelatedToAccount__c' );
		}
		Test.StopTest();

		System.assert (!result, 'Empty user user should NOT have access');
	}

	@isTest
	private static void testFieldIsCreateable_emptyUserWithPermset() {

		User u = [SELECT Id FROM User WHERE LastName = 'Last UNIQUE NAME' LIMIT 1];
		Boolean result;

		Test.StartTest();
		System.runAs( u )
		{
			result = AccessControlValidator.fieldIsCreateable( 'Task', 'RelatedToAccount__c' );
		}
		Test.StopTest();

		System.assert (result, 'New user should have access');
	}
}
