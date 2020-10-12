public without sharing class PopulateNumberChildAccounts_Schedule implements Schedulable, Database.Batchable<SObject> {

	@TestVisible
	private final String ACCOUNT_HISTORY_QUERY = 'SELECT AccountId FROM AccountHistory WHERE CreatedDate = TODAY AND Field IN (\'INT_ParentOrganizationNumber__c\', \'created\')';

	public void execute( SchedulableContext sc ) {
		PopulateNumberChildAccounts_Schedule btch = new PopulateNumberChildAccounts_Schedule();
		Database.executeBatch( btch, 2000 );
	}

	public Database.QueryLocator start( Database.BatchableContext BC ) {
		return Database.getQueryLocator( this.ACCOUNT_HISTORY_QUERY );
	}

	public void execute( Database.BatchableContext BC, List<AccountHistory> scope ) {
		//get accound Ids
		Set<Id> accountIds = new Set<Id>();
		for ( AccountHistory accountHistory : scope ) {
			accountIds.add( accountHistory.AccountId );
		}

		//get parent Ids
		Set<Id> parentIds = new Set<Id>();
		for ( Account acc:[SELECT ParentId FROM Account WHERE Id in:accountIds AND ParentId != null] ) {
			parentIds.add( acc.ParentId );
		}

		//get number of child accounts
		Map<Id, Integer> numberOfChildAccountsByParentId = new Map<Id, Integer>();
		AggregateResult[] arNumberOfAccounts = [SELECT COUNT( Id ) numberOfAccounts, ParentId FROM Account WHERE ParentId =:parentIds GROUP BY ParentId];
		for ( AggregateResult ar:arNumberOfAccounts ) {
			numberOfChildAccountsByParentId.put( (Id) ar.get( 'ParentId' ), (Integer)ar.get( 'numberOfAccounts' ) );
		}

		//update numberOfChildAccounts
		List<Account> accountsToUpdate = [SELECT Id, TAG_NumberOfChildAccounts__c FROM Account WHERE Id in:numberOfChildAccountsByParentId.keySet()];
		for ( Account parentAcc:accountsToUpdate ) {
			parentAcc.TAG_NumberOfChildAccounts__c = numberOfChildAccountsByParentId.get( parentAcc.Id );
		}

		update accountsToUpdate;
	}
	public void finish( Database.BatchableContext BC ) {
	}
}
