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
		            ( AccountId = : accountId ) ORDER BY CreatedDate DESC];

	}
	@AuraEnabled
	public static List<AccountMessagesWrapper> convertAccountHistoryToWrapper( List<AccountHistory> historyList ) {
		List<AccountMessagesWrapper> wrapper = new List<AccountMessagesWrapper>();

		for ( Integer i = 0; i < historyList.size(); i++ ) {

			Datetime eventDate = historyList[i].CreatedDate;
			Object newValue = historyList[i].NewValue;
			Object oldValue = historyList[i].OldValue;
			String field = historyList[i].Field;

			Integer counter = +i;
			String value = 'Bedriften er ';

			Boolean isNew = newValue == true && oldValue == false;
			//Boolean isOld = oldValue == true && newValue == false;

			if ( field == 'INT_IsBankrupt__c' ) {
				if ( isNew ) {
					value = value + 'konkurs';
				} else {
					value = value + 'ikke lenger konkurs';
				}
			}

			if ( field == 'INT_IsInForcedSettlementOrResolution__c' ) {
				if ( isNew ) {
					value = value + 'under tvangsavvikling';
				} else {
					value = value + 'ikke lenger under tvangsavvikling';
				}
			}
			if ( field == 'INT_IsInLiquidation__c' ) {
				if ( isNew ) {
					value = value + 'under avvikling';
				} else {
					value = value + 'ikke lenger under avvikling';
				}
			}

			/*Boolean isBankrupt;
			       Boolean isInLiquidation;
			       Boolean isInForcedSettlementOrResolution;*/

			/*Boolean isBankrupt = (newValue == true && oldValue == false) &&
			                     (field  == 'INT_IsBankrupt__c');

			   Boolean isInLiquidation = (newValue == true && oldValue == false) &&
			                          (field == 'INT_IsInLiquidation__c');

			   Boolean isInForcedSettlementOrResolution = (newValue == true && oldValue == false) &&
			                                           (field == 'INT_IsInForcedSettlementOrResolution__c');*/




			//AccountMessagesWrapper history = new AccountMessagesWrapper( isBankrupt, isInLiquidation, isInForcedSettlementOrResolution, eventDate, counter, isOld );
			AccountMessagesWrapper history = new AccountMessagesWrapper( eventDate, counter, value );
			wrapper.add( history );
		}

		return wrapper;

	}
}




