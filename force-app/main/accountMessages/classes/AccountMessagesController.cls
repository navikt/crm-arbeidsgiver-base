public with sharing class AccountMessagesController {

	@AuraEnabled(cacheable = true)
	public static List<AccountMessagesWrapper> getData( String recordId ) {
		List<AccountHistory> historyList = queryAccountHistory( recordId );
		List<AccountMessagesWrapper> wrapper = convertAccountHistoryToWrapper( historyList );

		return wrapper;

	}
	@AuraEnabled
	public static List<AccountHistory> queryAccountHistory( Id accountId ) {
		return [SELECT
		        AccountId, CreatedDate, Field, IsDeleted, NewValue, OldValue
		        FROM AccountHistory
		        WHERE
		            ( Field = 'INT_IsInForcedSettlementOrResolution__c' OR Field = 'INT_IsInLiquidation__c' OR Field = 'INT_IsBankrupt__c' ) AND
		            ( AccountId = : accountId )];

	}
	@AuraEnabled
	public static List<AccountMessagesWrapper> convertAccountHistoryToWrapper( List<AccountHistory> historyList ) {
		List<AccountMessagesWrapper> wrapper = new List<AccountMessagesWrapper>();

		for ( Integer i = 0; i < historyList.size(); i++ ) {

			Integer counter = +i;
			String value;
			Datetime eventDate = historyList[i].CreatedDate;
			Object newValue = historyList[i].NewValue;
			Object oldValue = historyList[i].OldValue;
			String field = historyList[i].Field;

			Boolean isNew = newValue == true && oldValue == false;
			Boolean isOld = oldValue == true && newValue == false;

			if ( field == 'INT_IsBankrupt__c' ) {
				value = 'isBankrupt';
			}
			if ( field == 'INT_IsInForcedSettlementOrResolution__c' ) {
				value = 'isInForcedSettlementOrResolution';
			}
			if ( field == 'INT_IsInLiquidation__c' ) {
				value = 'isInLiquidation';
			}
			/*Boolean isBankrupt;
			       Boolean isInLiquidation;
			       Boolean isInForcedSettlementOrResolution;*/

			/*isBankrupt = (newValue == true && oldValue == false) &&
			             (field  == 'INT_IsBankrupt__c');

			   isInLiquidation = (newValue == true && oldValue == false) &&
			                  (field == 'INT_IsInLiquidation__c');

			   isInForcedSettlementOrResolution = (newValue == true && oldValue == false) &&
			                                   (field == 'INT_IsInForcedSettlementOrResolution__c');*/


			//history = new AccountMessagesWrapper( isBankrupt, isInLiquidation, isInForcedSettlementOrResolution, eventDate, counter );
			AccountMessagesWrapper history = new AccountMessagesWrapper( eventDate, counter, value, isNew, isOld );
			wrapper.add( history );
		}

		return wrapper;

	}
}




