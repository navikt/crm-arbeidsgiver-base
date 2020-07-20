@isTest
private without sharing class CustomNotificationControllerTest {
	@isTest
	private static void testGetWarning() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test', Description = 'test', TAG_NoPersonInformation__c = true );
		insert ta;

		Test.StartTest();
		String res = CustomNotificationController.getFieldValue( ta.Id, 'Description' );
		Test.StopTest();

		System.assertEquals( 'test', res, 'Since Description is test, the returned value should be the same' );
	}

	@isTest
	private static void testGetWarning_empty() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];
		Task ta = new Task( WhatId = acc.Id, ActivityDate = Date.today(), Subject = 'test', Description = '', TAG_NoPersonInformation__c = true );
		insert ta;

		Test.StartTest();
		String res = CustomNotificationController.getFieldValue( ta.Id, 'Description' );
		Test.StopTest();

		System.assertEquals( null, res, 'Since Description is empty, the returned value should be empty' );
	}

	@isTest
	private static void testGetWarning_noFieldExists() {
		DataUsePurpose dup = new DataUsePurpose( Name = 'test' );
		insert dup;

		Test.StartTest();
		String res = CustomNotificationController.getFieldValue( dup.Id, 'Warning__c' );
		Test.StopTest();

		System.assertEquals( null, res, 'Since Warning__c does not exist on DataUsePurpose, the returned value should be empty' );
	}
}
