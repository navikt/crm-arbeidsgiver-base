public with sharing class AccountMessagesController {

	@AuraEnabled(cacheable = true)
	public static AccountMessagesWrapper getData( String recordId ) {
		Account account = getAccount( recordId );
		AccountMessagesWrapper wrapper = convertAccountHistoryToWrapper( account );

		return wrapper;
	}

	@AuraEnabled
	public static Account getAccount( Id recordId ) {
		Account parent = [SELECT ParentId FROM Account WHERE Id =:recordId];
        Id currentId;
		if ( parent.ParentId != null ) {
           currentId = parent.ParentId;
		} else {
            currentId = recordId;	
        }

        Account currentAccount = [SELECT Id, ParentId, CreatedDate, INT_IsBankrupt__c, INT_IsInForcedSettlementOrResolution__c FROM Account WHERE  ( INT_IsBankrupt__c = TRUE OR INT_IsInForcedSettlementOrResolution__c = TRUE ) AND Id = :currentId]; 
        return currentAccount;
    }
    
	@AuraEnabled
	public static Account findRelatedAccount( Id accountId, String value ) {
		Account currentAccount = [SELECT Name FROM Account WHERE Id =:accountId LIMIT 1][0];
		String newAccountName = currentAccount.Name + value;
		Account newAccount = [SELECT Id, Name FROM Account WHERE Name =:newAccountName AND INT_OrganizationalStructure__c = 'AAFY'];

		return newAccount;
	}

	@AuraEnabled
	public static AccountMessagesWrapper convertAccountHistoryToWrapper( Account account ) {
		String value = 'Denne virksomheten er ';
		Id accountId = account.Id;
		Account relatedAccount;
		Id relatedAccountId;


		if ( account.INT_IsBankrupt__c == true ) {
			relatedAccount = findRelatedAccount( accountId, ' KONKURSBO' );
			relatedAccountId = relatedAccount.Id;
			value = value + 'konkurs';
		}
		if ( account.INT_IsInForcedSettlementOrResolution__c ) {
			relatedAccount = findRelatedAccount( accountId, ' TVANGSAVVIKLINGSBO' );
			relatedAccountId = relatedAccount.Id;
			value = value + 'under tvangsavvikling';
		}

		AccountMessagesWrapper wrapper = new AccountMessagesWrapper( relatedAccountId, value );

		return wrapper;
	}
}




