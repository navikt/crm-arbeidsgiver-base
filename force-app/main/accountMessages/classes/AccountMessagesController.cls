public with sharing class AccountMessagesController {
	@AuraEnabled(cacheable = true)
	public static List<AccountHistory> getAccountHistory( String recordId ) {
		List<AccountHistory> acthist = [SELECT AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue FROM AccountHistory WHERE ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND AccountId = : recordId];

		return acthist;
	}
	@AuraEnabled(cacheable = true)
	public static List<AccountHistory> getParentAccountHistory( String recordId ) {
		Account account = [SELECT ParentId FROM Account WHERE Id =:recordId];
		List<AccountHistory> pacthist = [SELECT AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue FROM AccountHistory WHERE ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND AccountId = : account.ParentId];

		return pacthist;
	}
}
