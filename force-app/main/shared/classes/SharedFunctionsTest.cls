@isTest
private without sharing class SharedFunctionsTest {
    @testSetup
    private static void setup() {
        createDefaultAccounts();
    }

    @isTest
    private static void testFetchAccounts() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        Account acc2 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777');
        insert new List<Account>{ acc, acc2 };
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'tore.toresen@example.com',
            AccountId = acc.Id
        );
        insert con;

        Test.StartTest();
        Map<String, Account> result = SharedFunctions.fetchAccounts(
            new List<String>{ acc.INT_OrganizationNumber__c, acc2.INT_OrganizationNumber__c }
        );
        Test.StopTest();

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(acc.Id, result.get(acc.INT_OrganizationNumber__c).Id, 'Should be same account');
        System.assertEquals(acc2.Id, result.get(acc2.INT_OrganizationNumber__c).Id, 'Should be same account');
        System.assertEquals(
            1,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_create() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '99999999',
            'kurs'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(acc.Id, result.get('test@test.com').AccountId, 'Should be same account');
        System.assert(result.get('test@test.com').Source__c.contains('kurs'), 'Should be same account');
        System.assertEquals(
            1,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_nullOrgNo() {
        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            null,
            'kurs'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = new Map<String, Account>();

        List<Contact> contacts = [SELECT Id, Account.INT_OrganizationNumber__c FROM Contact];
        System.assertEquals(0, contacts.size(), 'before, zero contacts');

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, Account.INT_OrganizationNumber__c FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, one contact');

        Id defaultAccountId = SharedFunctions_FetchOrCreateContact.getDefaultAccountId();
        System.assertEquals(
            defaultAccountId,
            contacts[0].Account.INT_OrganizationNumber__c,
            'Contact should have the default account.'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_emptyOrgNo() {
        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '',
            'kurs'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = new Map<String, Account>();

        List<Contact> contacts = [SELECT Id, Account.INT_OrganizationNumber__c FROM Contact];
        System.assertEquals(0, contacts.size(), 'before, zero contacts');

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, Account.INT_OrganizationNumber__c FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, one contact');

        Id defaultAccountId = SharedFunctions_FetchOrCreateContact.getDefaultAccountId();
        System.assertEquals(
            defaultAccountId,
            contacts[0].Account.INT_OrganizationNumber__c,
            'Contact should have the default account'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_nullOrgNo_existingContact() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'Toråsen',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@domain.com',
            null,
            'kurs'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = new Map<String, Account>();

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'before, one contact');

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, AccountId FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, one contact');
        System.assertEquals(acc.Id, contacts[0].AccountId, 'Contact should have the default account.');
    }

    @isTest
    private static void testFetchOrCreateContact_emptyOrgNo_existingContact() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'Toråsen',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@domain.com',
            '',
            'kurs'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = new Map<String, Account>();

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'before, one contact');

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, AccountId FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, one contact');
        System.assertEquals(acc.Id, contacts[0].AccountId, 'Contact should have the default account');
    }

    @isTest
    private static void testFetchOrCreateContact_emptyEmail() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        Account acc2 = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '677777');
        insert new List<Account>{ acc, acc2 };
        Contact con = new Contact(TAG_Informed__c = true, LastName = 'test', FirstName = 'test', AccountId = acc.Id);
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            '',
            '677777',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'Before, only 1 contact');

        Test.StartTest();
        SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id FROM Contact];
        System.assertEquals(2, contacts.size(), 'After, 2 contacts despite empty email');
    }

    @isTest
    private static void testFetchOrCreateContact_invalidEmail() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test @domain.com',
            '99999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper2 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'testÆØÅ@domain.com',
            '99999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper3 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@domaincom',
            '99999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper4 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'te@st@domain.com',
            '99999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper5 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@domain',
            '99999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper6 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test£@domain.com',
            '99999999',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            wrapper,
            wrapper2,
            wrapper3,
            wrapper4,
            wrapper5,
            wrapper6
        };

        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'Before, only 1 contact');

        Test.StartTest();
        SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, InvalidEmail__c, Email FROM Contact];
        System.assertEquals(6, contacts.size(), 'After, 6 contacts despite invalid email');

        for (Contact c : contacts) {
            System.assertEquals(null, c.Email, 'Email should be null, as the emailed added is invalid');
            System.assertNotEquals(
                null,
                c.InvalidEmail__c,
                'InvalidEmail__c should not be null, as the email added is invalid'
            );
        }
    }

    @isTest
    private static void testFetchOrCreateContact_invalidEmailExisting_CreateNewWithInvalidEmail() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'Toråsen',
            InvalidEmail__c = 'test @domain.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test @domain.com',
            '99999999',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };

        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'Before, only 1 contact');

        Test.StartTest();
        SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        contacts = [SELECT Id, InvalidEmail__c, Email FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, still only one contact despite invalid email');

        for (Contact c : contacts) {
            System.assertEquals(null, c.Email, 'Email should be null, as the emailed added is invalid');
            System.assertEquals(
                'test @domain.com',
                c.InvalidEmail__c,
                'InvalidEmail__c should not be null, as the email added is invalid'
            );
            System.assertEquals(con.Id, c.Id, 'Same contact');
        }
    }

    @isTest
    private static void testFetchOrCreateContact_existingContact() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '99999999',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        System.assertEquals(con.Id, result.get('test@test.com').Id, 'Should be same existing contact');

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(
            1,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_existingContact_newSource() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Source__c = 'Kurs',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '99999999',
            'Permittering'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        Test.StartTest();
        SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        con = [SELECT Id, Source__c FROM contact WHERE Id = :con.Id LIMIT 1];
        System.assert(con.Source__c.contains('Kurs'), 'Source should contain kurs');
        System.assert(con.Source__c.contains('Permittering'), 'Source should contain Permittering');
    }

    @isTest
    private static void testFetchOrCreateContact_existingContactOnAnotherAccount() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        Account acc2 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777');
        insert new List<Account>{ acc, acc2 };
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '77777777',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(con.Id, result.get('test@test.com').Id, 'Should be same existing contact');
        System.assertEquals(
            2,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_existingContactOnAnotherAccount_sameUserMultipleInsertions() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        Account acc2 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '77777777');
        Account acc3 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '4444');
        insert new List<Account>{ acc, acc2, acc3 };

        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '77777777',
            'test'
        );
        SharedFunctions_ContactModel wrapper2 = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '4444',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper, wrapper2 };

        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(
            new List<String>{ wrapper.companyNumber, wrapper2.companyNumber }
        );

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(con.Id, result.get('test@test.com').Id, 'Should be same existing contact');
        System.assertEquals(
            3,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_existingContactOnAnotherAccount_multipleUsers() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '77777777');
        Account acc2 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '4444');
        Account acc3 = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '9999999');
        Account acc4 = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '3333');
        insert new List<Account>{ acc, acc2, acc3, acc4 };

        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        Contact con2 = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test_new@test.com',
            AccountId = acc2.Id
        );
        insert new List<Contact>{ con, con2 };

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'test@test.com',
            '9999999',
            'test'
        );
        SharedFunctions_ContactModel wrapper2 = new SharedFunctions_ContactModel(
            'test2',
            'etternavn2',
            '34430400',
            'test_new@test.com',
            '3333',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper, wrapper2 };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(
            new List<String>{ wrapper.companyNumber, wrapper2.companyNumber }
        );

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(con.Id, result.get('test@test.com').Id, 'Should be same existing contact');
        System.assertEquals(
            4,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testFetchOrCreateContact_uppcaseEmail() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@test.com',
            AccountId = acc.Id
        );
        insert con;

        SharedFunctions_ContactModel wrapper = new SharedFunctions_ContactModel(
            'test',
            'etternavn',
            '90080900',
            'Test@test.com',
            '77777777',
            'test'
        );
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{ wrapper };
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(new List<String>{ wrapper.companyNumber });

        Test.StartTest();
        Map<String, Contact> result = SharedFunctions.fetchOrCreateContact(wrapperList, accountMap);
        Test.StopTest();

        System.assertEquals(con.Id, result.get('test@test.com').Id, 'Should be same existing contact');
    }

    // helper functions

    private static void createDefaultAccounts() {
        insert new Account(name = 'Kontakter uten konto', INT_OrganizationNumber__c = 'AG_DEFAULT');
    }
}
