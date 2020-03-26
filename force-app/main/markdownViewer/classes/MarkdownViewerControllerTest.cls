@isTest
private without sharing class MarkdownViewerControllerTest {

	@testSetup
	private static void setup() {
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TAG_default' LIMIT 1];
		User u = TAG_TestDataFactory.createStandardUser();
		insert new PermissionSetAssignment( AssigneeId = U.id, PermissionSetId = ps.Id );

	}

	@isTest
	private static void testGetData() {

		TemporaryLayoff__c tl = new TemporaryLayoff__c();
		tl.OtherComments__c = '### Årsak\nSlett denne\n### Yrker\nkokk\n### Annet\n';
		insert tl;

		User u = [SELECT Id FROM User WHERE LastName = 'Last UNIQUE NAME' LIMIT 1];
		String results;

		Test.StartTest();
		System.runAs( u )
		{
			results = MarkdownViewerController.getData( tl.Id, 'TemporaryLayoff__c', 'OtherComments__c' );
		}
		Test.StopTest();

		System.assertNotEquals( null, results, 'Results should not be null' );
		System.assertEquals( tl.OtherComments__c.replace( '\n', '' ), results.replace( '\n', '' ), 'Should just be the same data' );
	}

	@isTest
	private static void testGetData_noAccess() {

		TemporaryLayoff__c tl = new TemporaryLayoff__c();
		tl.OtherComments__c = '### Årsak\nSlett denne\n### Yrker\nkokk\n### Annet\n';
		insert tl;

		User u = TAG_TestDataFactory.createStandardUser();
		String results;

		Test.StartTest();
		System.runAs( u )
		{
			results = MarkdownViewerController.getData( tl.Id, 'TemporaryLayoff__c', 'OtherComments__c' );
		}
		Test.StopTest();

		System.assertEquals( null, results, 'Results should be null' );

	}
}
