@isTest
private without sharing class AccountMessagesController_Test {
    @testSetup
    private static void setup() {
        List<Account> acts = TAG_TestDataFactory.createAccounts(7);
        // Bankrupt parent account
        acts[0].INT_IsBankrupt__c = true;
        // Child account with bankrupt parent
        acts[1].ParentId = acts[0].Id;
        // Related KONKURSBO account
        acts[2].Name = 'test KONKURSBO';
        acts[2].INT_OrganizationalStructure__c = 'AAFY';

        // Forced settlement parent account
        acts[3].INT_IsInForcedSettlementOrResolution__c = true;
        // Child account with forced settlement parent
        acts[4].ParentId = acts[3].Id;
        // Related TVANGSAVVIKLINGSBO account
        acts[5].Name = 'test TVANGSAVVIKLINGSBO';
        acts[5].INT_OrganizationalStructure__c = 'AAFY';

        // Deleted account
        acts[6].IsDeletedEmployer__c = true;
        acts[6].EmployerDeletedDate__c = Date.newInstance(2025, 1, 1);
        update acts;
    }

    @isTest
    private static void returnMessageWhenDeleted() {
        Account account = [SELECT Id FROM Account WHERE IsDeletedEmployer__c = TRUE LIMIT 1];
        Test.StartTest();
        AccountMessagesWrapper result = AccountMessagesController.getData(account.Id);
        Test.StopTest();
        Assert.areEqual('Denne virksomheten er avsluttet(1.1.2025)', result.deletedMessage);
    }
    @isTest
    private static void returnMessageWhenForcedSettlement() {
        Account account = [
            SELECT Id, ParentId
            FROM Account
            WHERE Parent.INT_IsInForcedSettlementOrResolution__c = TRUE
            LIMIT 1
        ];
        Account relatedAccount = [SELECT Id FROM Account WHERE Name = 'test TVANGSAVVIKLINGSBO' LIMIT 1];
        Test.StartTest();
        AccountMessagesWrapper resultChildAccount = AccountMessagesController.getData(account.Id);
        AccountMessagesWrapper resultParentAccount = AccountMessagesController.getData(account.ParentId);
        Test.StopTest();
        Assert.areEqual(
            relatedAccount.Id,
            resultChildAccount.accountId,
            'Wrapper for child account should contain related account'
        );
        Assert.areEqual(
            relatedAccount.Id,
            resultParentAccount.accountId,
            'Wrapper for parent account should contain related account'
        );
        Assert.areEqual(
            'Denne virksomheten er under tvangsavvikling',
            resultChildAccount.field,
            'Child account should return message for forced settlement'
        );
        Assert.areEqual(
            'Denne virksomheten er under tvangsavvikling',
            resultParentAccount.field,
            'Parent account should return message for forced settlement'
        );
    }
    @isTest
    private static void returnMessageWhenBankrupt() {
        Account account = [
            SELECT Id, ParentId
            FROM Account
            WHERE Parent.INT_IsBankrupt__c = TRUE
            LIMIT 1
        ];
        Account relatedAccount = [SELECT Id FROM Account WHERE Name = 'test KONKURSBO' LIMIT 1];
        Test.StartTest();
        AccountMessagesWrapper resultChildAccount = AccountMessagesController.getData(account.Id);
        AccountMessagesWrapper resultParentAccount = AccountMessagesController.getData(account.ParentId);
        Test.StopTest();
        Assert.areEqual(
            relatedAccount.Id,
            resultChildAccount.accountId,
            'Wrapper for child account should contain related account'
        );
        Assert.areEqual(
            relatedAccount.Id,
            resultParentAccount.accountId,
            'Wrapper for parent account should contain related account'
        );
        Assert.areEqual(
            'Denne virksomheten er konkurs',
            resultChildAccount.field,
            'Child account should return message for forced settlement'
        );
        Assert.areEqual(
            'Denne virksomheten er konkurs',
            resultParentAccount.field,
            'Parent account should return message for forced settlement'
        );
    }

    @isTest
    private static void returnNullWhenActive() {
        Account account = [
            SELECT Id
            FROM Account
            WHERE
                INT_IsInForcedSettlementOrResolution__c = FALSE
                AND INT_IsBankrupt__c = FALSE
                AND IsDeletedEmployer__c = FALSE
                AND Parent.INT_IsInForcedSettlementOrResolution__c = FALSE
                AND Parent.INT_IsBankrupt__c = FALSE
                AND Parent.IsDeletedEmployer__c = FALSE
            LIMIT 1
        ];
        Test.StartTest();
        AccountMessagesWrapper result = AccountMessagesController.getData(account.Id);
        Test.StopTest();
        Assert.areEqual(null, result, 'Should return null when account is active');
    }

    @isTest
    private static void shouldHandleMissingOrBadData() {
        Assert.areEqual(null, AccountMessagesController.getData('badId'), 'Should return null');

        Account bankruptAccount = [
            SELECT Id, ParentId
            FROM Account
            WHERE Parent.INT_IsBankrupt__c = TRUE
            LIMIT 1
        ];
        Assert.areEqual(
            null,
            AccountMessagesController.findRelatedAccount(bankruptAccount.Id, 'XYZ'),
            'Should handle missing related accounts'
        );

        delete bankruptAccount;
        Assert.areEqual(
            null,
            AccountMessagesController.getAccount(bankruptAccount.Id),
            'Should return null if account does not exist'
        );
    }
}
