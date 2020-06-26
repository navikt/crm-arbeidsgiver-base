@isTest
private without sharing class DeleteAccountTeamTest {
	@isTest
	private static void testAccountTeamDelete() {
		List<Account> accounts = TAG_TestDataFactory.createAccounts( 1 );
		User standardUser = TAG_TestDataFactory.createStandardUser( 'Last UNIQUE NAME' );

		List<AccountTeamMember> atms = new List<AccountTeamMember>();
		AccountTeamMember atm = new AccountTeamMember();

		atm.AccountId = accounts[0].Id;
		atm.UserId = standardUser.Id;
		atm.TAG_Active__c = true;

		atms.add( atm );
		insert atms;

		atm.TAG_Active__c = false;
		update atms;

		System.assertEquals( atms.size(), 1 );

		Test.StartTest();
		Test.StopTest();

		atms = [SELECT Id FROM AccountTeamMember];
		System.assertEquals( atms.size(), 0 );
	}
	@isTest
	private static void testAccountTeamDelete_DeleteMultipleMembers() {
		List<Account> accounts = TAG_TestDataFactory.createAccounts( 5 );
		User standardUser = TAG_TestDataFactory.createStandardUser( 'Last UNIQUE NAME' );

		List<AccountTeamMember> atms = new List<AccountTeamMember>();

		for ( Integer i = 0; i < 5; i++ ) {
			AccountTeamMember atm = new AccountTeamMember();
			atm.AccountId = accounts[i].Id;
			atm.UserId = standardUser.Id;
			atm.TAG_Active__c = true;
			atms.add( atm );
		}
		insert atms;

		atms[0].TAG_Active__c = false;
		atms[2].TAG_Active__c = false;
		update atms;

		System.assertEquals( atms.size(), 5 );

		Test.StartTest();
		Test.StopTest();

		atms = [SELECT Id FROM AccountTeamMember];
		System.assertEquals( atms.size(), 3 );
	}
	@isTest
	private static void testAccountTeamDelete_UpdateWithoutDeleting() {
		List<Account> accounts = TAG_TestDataFactory.createAccounts( 1 );
		User standardUser = TAG_TestDataFactory.createStandardUser( 'Last UNIQUE NAME' );

		List<AccountTeamMember> atms = new List<AccountTeamMember>();
		AccountTeamMember atm = new AccountTeamMember();

		atm.AccountId = accounts[0].Id;
		atm.UserId = standardUser.Id;
		atm.TAG_Active__c = true;

		atms.add( atm );
		insert atms;

		atm.TAG_Active__c = true;
		update atms;

		System.assertEquals( atms.size(), 1 );

		Test.StartTest();
		Test.StopTest();

		atms = [SELECT Id FROM AccountTeamMember];
		System.assertEquals( atms.size(), 1 );
	}
}
