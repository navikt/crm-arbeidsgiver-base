public with sharing class PopulateNavUnitForAllAccounts_Batch implements Database.Batchable<SObject> {
	private final String ACCOUNT_QUERY = 'SELECT Id, TAG_NavUnit__c, INT_MunicipalityNumber__c, ShippingPostalCode FROM Account WHERE IsPersonAccount=false AND INT_MunicipalityNumber__c!=null AND TAG_NavUnit__c=null LIMIT 50000';

	public Database.QueryLocator start( Database.BatchableContext BC ) {
		return Database.getQueryLocator( this.ACCOUNT_QUERY );
	}

	public void execute( Database.BatchableContext BC, List<Account> scope ) {
		List<Account> accountsWithUnits = NavUnitAccountRoutingService.getNavUnits( scope );
		update accountsWithUnits;
	}

	public void finish( Database.BatchableContext BC ) {
	}
}
