public with sharing class AccountMessagesController {
    private static final LoggerUtility LOGGER = new LoggerUtility();

    @AuraEnabled(cacheable=true)
    public static AccountMessagesWrapper getData(String recordId) {
        AccountMessagesWrapper wrapper = new AccountMessagesWrapper();
        Account account = getAccount(recordId);
        if (account == null) {
            return null;
        }
        if (isBusinessInsolvent(account)) {
            wrapper = convertAccountHistoryToWrapper(account.ParentId == null ? account : account.Parent);
        }

        if (isBusinessDeleted(account)) {
            wrapper.deletedMessage = createDeletedMessage(account);
        }

        if (wrapper.field == null && wrapper.deletedMessage == null) {
            return null;
        } else {
            return wrapper;
        }
    }

    @TestVisible
    private static Account getAccount(Id recordId) {
        Account currentAccount = [
            SELECT
                Id,
                ParentId,
                Parent.INT_IsBankrupt__c,
                Parent.INT_IsInForcedSettlementOrResolution__c,
                INT_IsBankrupt__c,
                INT_IsInForcedSettlementOrResolution__c,
                IsDeletedEmployer__c,
                EmployerDeletedDate__c,
                TAG_DeletedDateFormula__c
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
        return currentAccount;
    }

    @TestVisible
    private static Account findRelatedAccount(Id accountId, String value) {
        try {
            Account currentAccount = [SELECT Name FROM Account WHERE Id = :accountId LIMIT 1][0];
            String newAccountName = currentAccount.Name + value;
            Account newAccount = [
                SELECT Id, Name
                FROM Account
                WHERE Name = :newAccountName AND INT_OrganizationalStructure__c = 'AAFY'
            ];

            return newAccount;
        } catch (Exception e) {
            logError(accountId, e);
            return null;
        }
    }

    // om parent ikke er null - sjekk parent felt
    // om parent er null - sjekk account felt
    // Underselskap oppløses ikke uten at hovedselskapet også oppløses
    private static boolean isBusinessInsolvent(Account account) {
        if (account.ParentId != null) {
            return (account.Parent.INT_IsBankrupt__c == true || account.Parent.INT_IsInForcedSettlementOrResolution__c);
        } else {
            return (account.INT_IsBankrupt__c == true || account.INT_IsInForcedSettlementOrResolution__c == true);
        }
    }

    @TestVisible
    private static AccountMessagesWrapper convertAccountHistoryToWrapper(Account account) {
        String value = 'Denne virksomheten er ';
        Account relatedAccount;
        String relatedAccountId;
        if (account.INT_IsBankrupt__c == true) {
            relatedAccount = findRelatedAccount(account.Id, ' KONKURSBO');
            //relatedAccountId = relatedAccount.id;
            value = value + 'konkurs';
        }
        if (account.INT_IsInForcedSettlementOrResolution__c) {
            relatedAccount = findRelatedAccount(account.Id, ' TVANGSAVVIKLINGSBO');
            // relatedAccountId = relatedAccount.id;
            value = value + 'under tvangsavvikling';
        }
        return new AccountMessagesWrapper(relatedAccount?.id, value);
    }

    private static boolean isBusinessDeleted(Account account) {
        return account.IsDeletedEmployer__c;
    }

    private static String createDeletedMessage(Account account) {
        String deletedMessage = 'Denne virksomheten er avsluttet';
        if (account.EmployerDeletedDate__c == null) {
            deletedMessage = 'Denne virksomheten er avsluttet(' + account.TAG_DeletedDateFormula__c + ')';
        }
        return deletedMessage;
    }

    private static void logError(Id accountId, Exception e) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            accountId,
            e.getMessage(),
            e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        LOGGER.publish();
    }
}
