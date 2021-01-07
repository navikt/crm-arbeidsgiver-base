public without sharing class accountTeamMemberController {
	@AuraEnabled( cacheable = true )
	public static List<AccountTeamMember> getData( Id recordId ) {
		List<AccountTeamMember> actm = [SELECT Id, AccountId, toLabel( TeamMemberRole ), toLabel( Departments__c ), User.Name, User.CompanyName, User.MobilePhone FROM AccountTeamMember WHERE AccountId = :recordId];

		return actm;
	}

    
	@AuraEnabled
	public static void deleteTeamMember( Id atmId ) {
		AccountTeamMember recordToDelete = [SELECT Id FROM AccountTeamMember WHERE Id =:atmId];
		delete recordToDelete;
	}

}