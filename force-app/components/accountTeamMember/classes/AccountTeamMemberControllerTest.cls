@isTest
private without sharing class AccountTeamMemberControllerTest {
	@isTest
	private static void AccountTeamMemberControllerTest() {
		List<Account> accounts = TAG_TestDataFactory.createAccounts( 1 );
		User standardUser = TAG_TestDataFactory.createStandardUser( 'Last UNIQUE NAME' );

		List<AccountTeamMember> atms = new List<AccountTeamMember>();
		AccountTeamMember atm = new AccountTeamMember();

		atm.AccountId = accounts[0].Id;
		atm.UserId = standardUser.Id;

		atms.add( atm );
		insert atms;

		Test.StartTest();
		List<AccountTeamMember> result = accountTeamMemberController.getData( accounts[0].Id );
		accountTeamMemberController.deleteTeamMember( atms[0].Id );
		List<AccountTeamMember> deletedResult = accountTeamMemberController.getData( accounts[0].Id );
		Test.StopTest();

		System.assertEquals( atms.size(), result.size() );
		System.assertEquals( 0, deletedResult.size() );



	}
}
