public with sharing class SharedFunctions_FetchOrCreateContact {
    // will check both Email and InvalidEmail__c in case the email is Salesforce invalid (but not invalid for Norwegians, e.g., ÆØÅ)
    public static List<Contact> getExistingContacts(List<SharedFunctions_ContactModel> wrapperList) {
        Set<String> emails = new Set<String>();
        for (SharedFunctions_ContactModel cw : wrapperList) {
            emails.add(cw.email);
        }

        List<Contact> existingContacts = [
            SELECT Id, Email, FirstName, LastName, Account.INT_OrganizationNumber__c, InvalidEmail__c, Source__c
            FROM Contact
            WHERE (Email IN :emails AND Email != NULL) OR (InvalidEmail__c IN :emails AND InvalidEmail__c != NULL)
        ];

        return existingContacts;
    }

    // append new source if its not already on the contact
    public static void addNewSourceToExistingContacts(
        List<SharedFunctions_ContactModel> wrapperList,
        List<Contact> contacts
    ) {
        Map<String, SharedFunctions_ContactModel> wrapperMap = new Map<String, SharedFunctions_ContactModel>();
        for (SharedFunctions_ContactModel cw : wrapperList) {
            wrapperMap.put(cw.email, cw);
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact con : contacts) {
            SharedFunctions_ContactModel cw = wrapperMap.containsKey(con.Email)
                ? wrapperMap.get(con.Email)
                : wrapperMap.get(con.InvalidEmail__c);
            if (cw != null) {
                List<String> sources = con.Source__c != null ? con.Source__c.split(';') : new List<String>();
                String newSource = cw.source;
                if (!sources.contains(newSource)) {
                    sources.add(newSource);
                    con.Source__c = String.join(sources, ';');
                    contactsToUpdate.add(con);
                }
            }
        }
        update contactsToUpdate;
    }

    // create AccountContactRelation for unmapped contacts (e.g., when a contact is found originally but not mapped to the new account they're inquiring from)
    public static void mapUnmappedContacts(
        List<SharedFunctions_ContactModel> wrapperList,
        List<Contact> existingContacts,
        Map<String, Account> accountMap
    ) {
        Map<String, List<SharedFunctions_ContactModel>> contactWrapperMap = createMapOfContactWrapper(wrapperList);
        List<AccountContactRelation> relationships = new List<AccountContactRelation>();

        Map<Id, Id> contactAndAccountToMap = new Map<Id, Id>();
        for (Contact con : existingContacts) {
            String email = '';
            if (con.Email != null) {
                email = con.Email;
            } else if (con.InvalidEmail__c != null) {
                email = con.InvalidEmail__c;
            }

            if (contactWrapperMap.containsKey(email.toLowerCase())) {
                List<SharedFunctions_ContactModel> wrapper = contactWrapperMap.get(email.toLowerCase());
                for (SharedFunctions_ContactModel cw : wrapper) {
                    if (email == cw.email) {
                        String postedCompanyNumber = cw.companyNumber;
                        String currentCompanyNumber = con.Account.INT_OrganizationNumber__c;

                        if (
                            postedCompanyNumber != currentCompanyNumber && accountMap.containsKey(postedCompanyNumber)
                        ) {
                            Id accId = accountMap.get(postedCompanyNumber).Id;
                            relationships.add(new AccountContactRelation(AccountId = accId, ContactId = con.Id));
                        }
                    }
                }
            }
        }

        Database.insert(relationships, false); // insert all, and ignore errors on duplicates
    }

    /* Check for valid emails
	   -----------------------------

	   Not allowed:
	   - ÆØÅ
	   - Spaces
	   - Double period (..)
	   - More than one at (@)
	   - Signs except the A-Z, 0-9 and !#$%&*+-/=?^_`{|}~.
	 */

    public static Boolean checkIfValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);

        return MyMatcher.matches();
    }

    public static Map<String, List<SharedFunctions_ContactModel>> createMapOfContactWrapper(
        List<SharedFunctions_ContactModel> wrapperList
    ) {
        Map<String, List<SharedFunctions_ContactModel>> contactWrapperMap = new Map<String, List<SharedFunctions_ContactModel>>();
        for (SharedFunctions_ContactModel cw : wrapperList) {
            if (contactWrapperMap.containsKey(cw.email.toLowerCase())) {
                contactWrapperMap.get(cw.email.toLowerCase()).add(cw);
            } else {
                contactWrapperMap.put(cw.email.toLowerCase(), new List<SharedFunctions_ContactModel>{ cw });
            }
        }

        return contactWrapperMap;
    }

    public static Map<String, Contact> createContactMapWithEmailAsKey(List<Contact> existingContacts) {
        Map<String, Contact> contactMap = new Map<String, Contact>();

        for (Contact con : existingContacts) {
            if (con.Email != null) {
                contactMap.put(con.Email.toLowerCase(), con);
            } else if (con.InvalidEmail__c != null) {
                contactMap.put(con.InvalidEmail__c.toLowerCase(), con);
            }
        }

        return contactMap;
    }

    public static void createRemainingContacts(
        List<SharedFunctions_ContactModel> wrapperList,
        Map<String, Account> accountMap,
        Map<String, Contact> contactMap
    ) {
        List<Contact> newContacts = new List<Contact>();
        for (SharedFunctions_ContactModel cw : wrapperList) {
            if (!contactMap.containsKey(cw.email.toLowerCase())) {
                Id accountId = accountMap.containsKey(cw.companyNumber)
                    ? accountMap.get(cw.companyNumber).Id
                    : getDefaultAccountId();

                Contact con = new Contact(
                    FirstName = cw.firstName,
                    LastName = cw.lastName,
                    MobilePhone = cw.phone,
                    AccountId = accountId,
                    Source__c = cw.source
                );

                // if cw.email is a valid email, add the email
                if (SharedFunctions_FetchOrCreateContact.checkIfValidEmail(cw.email)) {
                    con.Email = cw.email;
                } else {
                    // if invalid, add it only to the invalid email field (to be later fixed by an employee)
                    con.InvalidEmail__c = cw.email;
                }

                contactMap.put(cw.email.toLowerCase(), con);
                newContacts.add(con);
            }
        }

        insert newContacts;
    }

    public static Id getDefaultAccountId() {
        List<Account> defaultAccount = [SELECT Id FROM Account WHERE INT_OrganizationNumber__c = 'AG_DEFAULT' LIMIT 1];
        Id defaultAccountId = defaultAccount.size() > 0 ? defaultAccount[0].Id : null;

        return defaultAccountId;
    }
}
