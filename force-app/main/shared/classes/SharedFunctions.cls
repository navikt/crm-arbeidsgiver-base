public with sharing class SharedFunctions {
    public static Map<String, Account> fetchAccounts(List<String> organisationNumbers) {
        List<Account> accounts = [
            SELECT Id, INT_OrganizationNumber__c, INT_MunicipalityNumber__c
            FROM Account
            WHERE
                INT_OrganizationNumber__c IN :organisationNumbers
                AND INT_OrganizationNumber__c != NULL
                AND IsPersonAccount = FALSE
        ];

        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : accounts) {
            accountMap.put(acc.INT_OrganizationNumber__c, acc);
        }

        return accountMap;
    }

    public static Map<String, Contact> fetchOrCreateContact(
        List<SharedFunctions_ContactModel> wrapperList,
        Map<String, Account> accountMap
    ) {
        List<Contact> existingContacts = SharedFunctions_FetchOrCreateContact.getExistingContacts(wrapperList);
        SharedFunctions_FetchOrCreateContact.addNewSourceToExistingContacts(wrapperList, existingContacts);
        SharedFunctions_FetchOrCreateContact.mapUnmappedContacts(wrapperList, existingContacts, accountMap);
        Map<String, Contact> contactMap = SharedFunctions_FetchOrCreateContact.createContactMapWithEmailAsKey(
            existingContacts
        );
        SharedFunctions_FetchOrCreateContact.createRemainingContacts(wrapperList, accountMap, contactMap);

        return contactMap;
    }
}
