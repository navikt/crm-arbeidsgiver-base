@isTest
private without sharing class AccountMessagesController_Test {
	@isTest
	private static void testGetAccounts_Test() {
		List<Account> acts = TAG_TestDataFactory.createAccounts( 4 );
		acts[0].INT_IsBankrupt__c = true;
		acts[1].ParentId = acts[0].Id;

		acts[2].Name = 'test KONKURSBO';
		acts[2].INT_OrganizationalStructure__c = 'AAFY';

		acts[3].INT_IsInForcedSettlementOrResolution__c = true;
		acts[4].ParentId = acts[2].Id;

		acts[5].Name = 'test TVANGSAVVIKLINGSBO';
		acts[5].INT_OrganizationalStructure__c = 'AAFY';



	}
}

