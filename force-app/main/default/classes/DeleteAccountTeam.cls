public without sharing class DeleteAccountTeam {

	@InvocableMethod
	public static void accountTeamDelete( List<AccountTeamMember> members ) {
		delete members;
	}
}