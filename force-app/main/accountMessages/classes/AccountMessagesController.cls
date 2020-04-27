public with sharing class AccountMessagesController {

	@AuraEnabled(cacheable = true)
	public static List<AccountMessagesWrapper> getData( String recordId ) {
		List<AccountHistory> historyList = queryAccountHistory( recordId );
		List<Account> accountList = queryAccounts( recordId );
		List<AccountMessagesWrapper> wrapper = convertAccountHistoryToWrapper( historyList, accountList );

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
	public static List<AccountMessagesWrapper> convertAccountHistoryToWrapper( List<AccountHistory> historyList, List<Account> accountList ) {
		List<AccountMessagesWrapper> wrapper = new List<AccountMessagesWrapper>();
		String isBankruptValue = 'Bedriften er konkurs';
		String isInForcedSettlemetValue = 'Bedriften er under tvangsavvikling';
		String isInLiquidationValue = 'Bedriften er under avvikling';
		Datetime eventDate;
		String value = '';

		for ( Integer i = 0; i < historyList.size(); i++ ) {

			eventDate = historyList[i].CreatedDate;
			Object newValue = historyList[i].NewValue;
			Object oldValue = historyList[i].OldValue;
			String field = historyList[i].Field;

			Boolean isNew = newValue == true && oldValue == false;

			if ( field == 'INT_IsBankrupt__c' ) {
				if ( isNew ) {
					value = isBankruptValue;
				} else {
					value = 'Bedriften er ikke lenger konkurs';
				}
			}

			if ( field == 'INT_IsInForcedSettlementOrResolution__c' ) {
				if ( isNew ) {
					value = isInForcedSettlemetValue;
				} else {
					value = 'Bedriften er ikke lenger under tvangsavvikling';
				}
			}
			if ( field == 'INT_IsInLiquidation__c' ) {
				if ( isNew ) {
					value = isInLiquidationValue;
				} else {
					value = 'Bedriften er ikke lenger under avvikling';
				}
			}

			AccountMessagesWrapper history = new AccountMessagesWrapper( eventDate, i, value );
			wrapper.add( history );
		}

		if ( historyList.size() < 0 && accountList.size() > 0 ) {
			for ( Integer i = 0; i < accountList.size(); i++ ) {
				Boolean isBankrupt = accountList[i].INT_IsBankrupt__c;
				Boolean isInLiquidation = accountList[i].INT_IsInLiquidation__c;
				Boolean isInForcedSettlemet = accountList[i].INT_IsInForcedSettlementOrResolution__c;
				eventDate = accountList[i].CreatedDate;
				AccountMessagesWrapper account;

				if ( isBankrupt ) {
					value = isBankruptValue;
					account = new AccountMessagesWrapper( eventDate, i, value );
					wrapper.add( account );
				}
				if ( isInLiquidation ) {
					value = isInLiquidationValue;
					account = new AccountMessagesWrapper( eventDate, i, value );
					wrapper.add( account );
				}
				if ( isInForcedSettlemet ) {
					value = isInForcedSettlemetValue;
					account = new AccountMessagesWrapper( eventDate, i, value );
					wrapper.add( account );
				}

				/*AccountMessagesWrapper account = new AccountMessagesWrapper( eventDate, i, value );
				   wrapper.add( account );*/
			}
		}

		return wrapper;
	}
	@AuraEnabled
	public static List<Account> queryAccounts( Id recordId ) {
		List<Account> accountList = [SELECT Id, CreatedDate, INT_IsBankrupt__c, INT_IsInLiquidation__c, INT_IsInForcedSettlementOrResolution__c FROM Account WHERE ( INT_IsBankrupt__c = TRUE OR INT_IsInForcedSettlementOrResolution__c = TRUE OR INT_IsInLiquidation__c = TRUE ) AND Id = : recordId];
		System.debug( accountList );

		return accountList;
	}
}




