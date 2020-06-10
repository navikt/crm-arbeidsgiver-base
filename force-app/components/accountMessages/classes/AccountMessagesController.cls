public with sharing class AccountMessagesController {

	@AuraEnabled(cacheable = true)
	public static AccountMessagesWrapper getData( String recordId ) {
		List<Account> historyList = getAccounts( recordId );
		AccountMessagesWrapper wrapper = convertAccountHistoryToWrapper( historyList );

		return wrapper;
	}

	@AuraEnabled
	public static List<Account> getAccounts( Id recordId ) {
		List<Account> parent = [SELECT ParentId FROM Account WHERE Id =:recordId];

		List<Account> bankrupt =
		[SELECT
		 Id, ParentId, CreatedDate, INT_IsBankrupt__c, INT_IsInLiquidation__c, INT_IsInForcedSettlementOrResolution__c
		 FROM Account
		 WHERE  ( INT_IsBankrupt__c = TRUE OR INT_IsInForcedSettlementOrResolution__c = TRUE OR INT_IsInLiquidation__c = TRUE )
		 AND Id = :recordId];

		if ( parent[0].ParentId != null ) {
			bankrupt =
			[SELECT
			 Id, ParentId, CreatedDate, INT_IsBankrupt__c, INT_IsInLiquidation__c, INT_IsInForcedSettlementOrResolution__c
			 FROM Account
			 WHERE ( INT_IsBankrupt__c = TRUE OR INT_IsInForcedSettlementOrResolution__c = TRUE OR INT_IsInLiquidation__c = TRUE )
			 AND Id = : parent[0].ParentId ];
		}

		return bankrupt;
	}
	@AuraEnabled
	public static List<Account> findRelatedAccounts( Id accountId, String value ) {

		List<Account> thisAccount = [SELECT Name FROM Account WHERE Id =:accountId LIMIT 1];
		String bankrupt = thisAccount[0].Name + value;
		List<Account> relatedAccounts = [SELECT Id, Name FROM Account WHERE Name =:bankrupt AND INT_OrganizationalStructure__c = 'AAFY'];

		return relatedAccounts;
	}

	@AuraEnabled
	public static AccountMessagesWrapper convertAccountHistoryToWrapper( List<Account> historyList ) {
		AccountMessagesWrapper wrapper;

		String isBankruptValue = 'Denne virksomheten er konkurs';
		String isInForcedSettlemetValue = 'Denne virksomheten er under tvangsavvikling';
		Id accountId;
		List<Account> relatedAccounts;
		String value = '';

		for ( Integer i = 0; i < historyList.size(); i++ ) {

			accountId = historyList[i].Id;

			if ( historyList[i].INT_IsBankrupt__c ) {
				relatedAccounts = findRelatedAccounts( accountId, ' KONKURSBO' );
				accountId = relatedAccounts[0].Id;
				value = isBankruptValue;

			}
			if ( historyList[i].INT_IsInForcedSettlementOrResolution__c ) {
				relatedAccounts = findRelatedAccounts( accountId, ' TVANGSAVVIKLINGSBO' );
				accountId = relatedAccounts[0].Id;
				value = isInForcedSettlemetValue;
			}

			wrapper = new AccountMessagesWrapper( accountId, i, value );
		}


		return wrapper;
	}
}




