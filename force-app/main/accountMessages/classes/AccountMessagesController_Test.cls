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
	private static void testConvertToWrapper_HistoryListIsNotEmpty() {
		List<Account> accList = TAG_TestDataFactory.createAccounts( 3 );

		List<AccountHistory> historyList = new List<AccountHistory>();
		AccountHistory historyElement = new AccountHistory( AccountId = accList[0].Id, Field = 'INT_IsBankrupt__c' );
		historyList.add( historyElement );
		historyElement = new AccountHistory( AccountId = accList[1].Id, Field = 'INT_IsInForcedSettlementOrResolution__c' );
		historyList.add( historyElement );
		historyElement = new AccountHistory( AccountId = accList[2].Id, Field = 'INT_IsInLiquidation__c' );
		historyList.add( historyElement );
		insert historyList;

		Test.StartTest();
		List<AccountMessagesWrapper> result = AccountMessagesController.convertAccountHistoryToWrapper( historyList, accList );
		Test.StopTest();
		System.assertEquals( 3, result.size(), 'Three history records returned' );

	}

	@isTest
	private static void testConvertToWrapper_HistoryListIsEmpty() {
		List<Account> accList = TAG_TestDataFactory.createAccounts( 3 );
		Account a = accList[0];
		Account b = accList[1];
		Account c = accList[2];

		a.INT_IsBankrupt__c = true;
		update a;

		b.INT_IsInLiquidation__c = true;
		update b;

		c.INT_IsInForcedSettlementOrResolution__c = true;
		update c;

		List<AccountHistory> historyList = new List<AccountHistory>();

		Test.StartTest();
		List<AccountMessagesWrapper> result = AccountMessagesController.convertAccountHistoryToWrapper( historyList, accList );
		Test.StopTest();

		System.assertEquals( 3, result.size(), 'Three elemets returned' );

	}
}

