public with sharing class AccountMessagesController {
	@AuraEnabled(cacheable = true)
	public static AccountMessagesWrapper getData( String recordId ) {
		//List<Account> parentAccount = [SELECT ParentId FROM Account WHERE Id =:recordId LIMIT 1];
		List<AccountHistory> historyList = [SELECT AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue FROM AccountHistory WHERE ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND AccountId = : recordId];

		//Logikk for å hente endringer

		AccountMessagesWrapper wrapper = new AccountMessagesWrapper( true, true, true, historyList[0].CreatedDate );

		return wrapper;

	}
}