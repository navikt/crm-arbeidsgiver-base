public without sharing class NumberOfChildForAllAccounts_Batch implements Database.Batchable<SObject> {
	private final String ACCOUNT_QUERY = 'SELECT Id, TAG_NumberOfChildAccounts__c FROM Account WHERE CRM_AccountType__c=\'J\'';

	public void execute( SchedulableContext sc ) {
		PopulateNumberChildAccounts_Schedule btch = new PopulateNumberChildAccounts_Schedule();
		Database.executeBatch( btch, 2000 );
	}

	public Database.QueryLocator start( Database.BatchableContext BC ) {
		return Database.getQueryLocator( this.ACCOUNT_QUERY );
	}

	public void execute( Database.BatchableContext BC, List<Account> scope ) {
		//get parent accound Ids
		Set<Id> parentAccountIds = new Set<Id>();
		for ( Account acc : scope ) {
			parentAccountIds.add( acc.Id );
		}

		//get number of child accounts
		Map<Id, Integer> numberOfChildAccountsByParentId = new Map<Id, Integer>();
		AggregateResult[] arNumberOfAccounts = [SELECT COUNT( Id ) numberOfAccounts, ParentId FROM Account WHERE ParentId =:parentAccountIds GROUP BY ParentId];
		for ( AggregateResult ar:arNumberOfAccounts ) {
			numberOfChildAccountsByParentId.put( (Id) ar.get( 'ParentId' ), (Integer)ar.get( 'numberOfAccounts' ) );
		}

		//update numberOfChildAccounts
		for ( Account parentAcc:scope ) {
			parentAcc.TAG_NumberOfChildAccounts__c = numberOfChildAccountsByParentId.get( parentAcc.Id );
		}

		update scope;
	}
	public void finish( Database.BatchableContext BC ) {
	}
}
