@isTest
private without sharing class TAG_ActivityTimelineHelperTest {

	@testSetup
	private static void setup() {

	}


	@isTest
	private static void testGetSOjectTypeFromRecordId() {

		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		String sObjtype = TAG_ActivityTimelineHelper.getSOjectTypeFromRecordId( acc.Id );
		Test.StopTest();

		System.assertEquals( 'Account', sObjtype, 'The returned value should be account based on the account ID' );

	}
}