public with sharing class AccountMessagesController {
    private static final LoggerUtility LOGGER = new LoggerUtility();

    @AuraEnabled(cacheable=true)
    public static AccountMessagesWrapper getData(String recordId) {
        AccountMessagesWrapper wrapper = new AccountMessagesWrapper();
        Account account;

        // Try to get account from database. Return null if no account was found. If an exception is thrown, log it and return null.
        try {
            account = getAccount(recordId);
            if (account == null) {
                return null;
            }
        } catch (Exception e) {
            logError(recordId, e);
            LOGGER.publish();
            return null;
        }
        // Try-catch for insolvent message. If an exception is thrown it is logged, but the method continues.
        try {
            if (isBusinessInsolvent(account)) {
                wrapper = convertAccountHistoryToWrapper(account.ParentId == null ? account : account.Parent);
            }
        } catch (Exception e) {
            logError(recordId, e);
            LOGGER.publish();
        }

        // Try-catch for deleted message. If an exception is thrown it is logged, but the method continues.
        try {
            if (isBusinessDeleted(account)) {
                wrapper.deletedMessage = createDeletedMessage(account);
            }
        } catch (Exception e) {
            logError(recordId, e);
            LOGGER.publish();
        }
        // Check if there are any messages to display. If not, return null.
        if (wrapper.field == null && wrapper.deletedMessage == null) {
            return null;
        } else {
            return wrapper;
        }
    }

    @TestVisible
    private static Account getAccount(Id recordId) {
        List<Account> currentAccount = [
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
            WHERE Id = :recordId AND IsPersonAccount = FALSE
            LIMIT 1
        ];
        if (currentAccount.isEmpty()) {
            return null;
        } else {
            return currentAccount[0];
        }
    }

    @TestVisible
    private static Account findRelatedAccount(Id accountId, String value) {
        Account currentAccount = [SELECT Name FROM Account WHERE Id = :accountId LIMIT 1][0];
        String newAccountName = currentAccount.Name + value;
        List<Account> newAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = :newAccountName AND INT_OrganizationalStructure__c = 'AAFY'
        ];
        if (newAccount.isEmpty()) {
            return null;
        } else {
            return newAccount[0];
        }
    }

    // Bankrupcy and forced settlement are only applicable to Enteties and not Sub-entities.
    // Therefore we need to check if the account is a Sub-entity or an Entity and check fields accordingly.
    // If account has parent it means it is a Sub-entity and we must check fields on parent account.
    // If no parent then it is an Entity and we must check fields on account.
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
            value = value + 'konkurs';
        }
        if (account.INT_IsInForcedSettlementOrResolution__c) {
            relatedAccount = findRelatedAccount(account.Id, ' TVANGSAVVIKLINGSBO');
            value = value + 'under tvangsavvikling';
        }
        return new AccountMessagesWrapper(relatedAccount?.id, value);
    }

    private static boolean isBusinessDeleted(Account account) {
        return account.IsDeletedEmployer__c;
    }

    private static String createDeletedMessage(Account account) {
        String deletedMessage = 'Denne virksomheten er avsluttet';
        if (account.EmployerDeletedDate__c != null) {
            deletedMessage = 'Denne virksomheten er avsluttet(' + account.TAG_DeletedDateFormula__c + ')';
        }
        return deletedMessage;
    }

    private static void logError(String accountId, Exception e) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            accountId,
            e.getMessage(),
            e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
    }
}
