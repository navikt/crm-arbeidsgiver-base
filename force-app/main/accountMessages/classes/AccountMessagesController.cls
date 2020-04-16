public with sharing class AccountMessagesController {
	@AuraEnabled(cacheable = true)
	public static AccountMessagesWrapper getData( String recordId ) {
		Datetime eventDate;
		Boolean isBankrupt;
		Boolean isInLiquidation;
		Boolean isInForcedSettlementOrResolution;

		//List<Account> parentAccount = [SELECT ParentId FROM Account WHERE Id =:recordId LIMIT 1];
		List<AccountHistory> historyList = [SELECT
		                                    AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue
		                                    FROM AccountHistory
		                                    WHERE
		                                        ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND
		                                        ( AccountId = : recordId )];
		System.debug( 'historyListst' + historyList );
		AccountMessagesWrapper wrapper;



		for ( Integer i = 0; i < historyList.size(); i++ ) {
			Object newValue = historyList[i].NewValue;
			Object oldValue = historyList[i].OldValue;
			String field = historyList[i].Field;

			isBankrupt = (newValue == true && oldValue == false) &&
			             (field  == 'INT_IsBankrupt__c');
			System.debug( 'isBankrupt' + isBankrupt );

			isInLiquidation = (newValue == true && oldValue == false) &&
			                  (field == 'INT_IsInLiquidation__c');
			System.debug( 'isInLiquidation' + isInLiquidation );
			isInForcedSettlementOrResolution = (newValue == true && oldValue == false) &&
			                                   (field == 'INT_IsInForcedSettlementOrResolution__c');
			System.debug( 'isInForcedSettlementOrResolution' + isInForcedSettlementOrResolution );

			eventDate = historyList[i].CreatedDate;


		}
		wrapper = new AccountMessagesWrapper( isBankrupt, isInLiquidation, isInForcedSettlementOrResolution, eventDate );

		return wrapper;
	}
}