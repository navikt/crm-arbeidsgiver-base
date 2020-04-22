@isTest
private without sharing class AccountMessagesController_Test {
	@isTest
	private static void testGetData() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		List<AccountMessagesWrapper> result = AccountMessagesController.getData( acc.Id );
		Test.StopTest();

		System.assertEquals( 0, result.size(), 'List is empty' );

	}
	@isTest
	private static void testQuery() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		Test.StartTest();
		List<AccountHistory> result = AccountMessagesController.queryAccountHistory( acc.Id );
		Test.StopTest();
		System.assertEquals( 0, result.size(), 'List is empty' );

	}
	@isTest
	private static void testConvertToWrapper() {
		Account acc = TAG_TestDataFactory.createAccounts( 1 )[0];

		List<AccountHistory> historyList = new List<AccountHistory>();
		AccountHistory historyElement = new AccountHistory( AccountId = acc.Id, Field = 'INT_IsBankrupt__c' );
		historyList.add( historyElement );
		historyElement = new AccountHistory( AccountId = acc.Id, Field = 'INT_IsInForcedSettlementOrResolution__c' );
		historyList.add( historyElement );
		historyElement = new AccountHistory( AccountId = acc.Id, Field = 'INT_IsInLiquidation__c' );
		historyList.add( historyElement );
		insert historyList;

		Test.StartTest();
		List<AccountMessagesWrapper> result = AccountMessagesController.convertAccountHistoryToWrapper( historyList );
		Test.StopTest();
		System.assertEquals( 3, result.size(), 'Three history record returned' );

	}
}

