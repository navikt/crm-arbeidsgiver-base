public without sharing class accountTeamMemberController {
	@AuraEnabled( cacheable = true )
	public static List<AccountTeamMember> getData( Id recordId ) {
		List<AccountTeamMember> actm = [SELECT Id, AccountId, TeamMemberRole, User.Name FROM AccountTeamMember WHERE AccountId = :recordId];

		return actm;
	}

	@AuraEnabled
	public static void deleteTeamMember( Id atmId ) {
		AccountTeamMember recordToDelete = [SELECT Id FROM AccountTeamMember WHERE Id =:atmId];
		delete recordToDelete;
	}

	@AuraEnabled
	public static void addTeamMember( Id recordId, Id userId, String role ) {
		AccountTeamMember memberToInsert = new AccountTeamMember( AccountId = recordId, UserId = userId, TeamMemberRole = role );
		insert memberToInsert;
	}
}