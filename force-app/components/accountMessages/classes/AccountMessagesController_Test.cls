@isTest
private without sharing class AccountMessagesController_Test {
	@isTest
	private static void testGetAccounts() {
		List<Account> acts = TAG_TestDataFactory.createAccounts( 6 );
		acts[0].INT_IsBankrupt__c = true;
		acts[1].ParentId = acts[0].Id;

		acts[2].Name = 'test KONKURSBO';
		acts[2].INT_OrganizationalStructure__c = 'AAFY';

		acts[3].INT_IsInForcedSettlementOrResolution__c = true;
		acts[4].ParentId = acts[3].Id;

		acts[5].Name = 'test TVANGSAVVIKLINGSBO';
		acts[5].INT_OrganizationalStructure__c = 'AAFY';

		update acts;

		Test.StartTest();
		AccountMessagesWrapper result = AccountMessagesController.getData( acts[0].Id );
		Account getBankruptAccount = AccountMessagesController.getAccount( acts[0].Id );
		Account getBankruptParent = AccountMessagesController.getAccount( acts[1].Id );
		Account getRelatedAccount = AccountMessagesController.findRelatedAccount( acts[1].Id, ' KONKURSBO' );
		Account getRelatedAccount2 = AccountMessagesController.findRelatedAccount( acts[3].Id, ' TVANGSAVVIKLINGSBO' );
		AccountMessagesWrapper accountIsBankrupt = AccountMessagesController.convertAccountHistoryToWrapper( acts[0] );
		AccountMessagesWrapper accountIsInForcedSettlement = AccountMessagesController.convertAccountHistoryToWrapper( acts[3] );
		System.debug( 'hei' + accountIsBankrupt );
		Test.StopTest();
		System.assertEquals( accountIsBankrupt.field, 'Denne virksomheten er konkurs' );
		System.assertEquals( accountIsInForcedSettlement.field, 'Denne virksomheten er under tvangsavvikling' );
		/*System.assertEquals( 1, getBankruptAccount.size() );
		   System.assertEquals( 1, getBankruptParent.size() );
		   System.assertEquals( acts[2].Id, getRelatedAccount[0].Id );*/
	}


}

