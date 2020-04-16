public with sharing class AccountMessagesController {
	@AuraEnabled(cacheable = true)
	public static List<AccountMessagesWrapper> getData( String recordId ) {
		Datetime eventDate;
		Boolean isBankrupt;
		Boolean isInLiquidation;
		Boolean isInForcedSettlementOrResolution;
		Integer counter = 0;

		List<AccountMessagesWrapper> wrapper = new List<AccountMessagesWrapper>();
		AccountMessagesWrapper history;

		List<AccountHistory> historyList = [SELECT
		                                    AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue
		                                    FROM AccountHistory
		                                    WHERE
		                                        ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND
		                                        ( AccountId = : recordId )];


		for ( Integer i = 0; i < historyList.size(); i++ ) {

			counter = +i;
			Object newValue = historyList[i].NewValue;
			Object oldValue = historyList[i].OldValue;
			String field = historyList[i].Field;

			isBankrupt = (newValue == true && oldValue == false) &&
			             (field  == 'INT_IsBankrupt__c');

			isInLiquidation = (newValue == true && oldValue == false) &&
			                  (field == 'INT_IsInLiquidation__c');

			isInForcedSettlementOrResolution = (newValue == true && oldValue == false) &&
			                                   (field == 'INT_IsInForcedSettlementOrResolution__c');
			eventDate = historyList[i].CreatedDate;
			history = new AccountMessagesWrapper( isBankrupt, isInLiquidation, isInForcedSettlementOrResolution, eventDate, counter );
			wrapper.add( history );
		}

		return wrapper;
	}
}