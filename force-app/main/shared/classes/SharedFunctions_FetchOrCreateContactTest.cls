@isTest
private without sharing class SharedFunctions_FetchOrCreateContactTest {
    @isTest
    private static void testGetExistingContacts_empty() {
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '99999999',
                'test'
            )
        };

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'Before, zero contacts');

        Test.StartTest();
        List<Contact> actual = SharedFunctions_FetchOrCreateContact.getExistingContacts(
            wrapperList
        );
        Test.StopTest();

        contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'After, zero contacts');
    }

    @isTest
    private static void testGetExistingContacts_existing() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '99999999',
                'test'
            )
        };

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'Before, 1 contacts');

        Test.StartTest();
        List<Contact> actual = SharedFunctions_FetchOrCreateContact.getExistingContacts(
            wrapperList
        );
        Test.StopTest();

        contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, 1 contacts');
    }

    @isTest
    private static void testAddNewSourceToExistingContacts() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Source__c = 'Permittering',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;

        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '99999999',
                'test'
            )
        };
        List<Contact> contacts = SharedFunctions_FetchOrCreateContact.getExistingContacts(
            wrapperList
        );

        Test.StartTest();
        SharedFunctions_FetchOrCreateContact.addNewSourceToExistingContacts(wrapperList, contacts);
        Test.StopTest();

        contacts = [SELECT Id, Source__c FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, 1 contacts');
        System.assert(contacts[0].Source__c.contains('test'), 'Should contain new source "test" ');
        System.assert(
            contacts[0].Source__c.contains('Permittering'),
            'Should contain old source "permittering" '
        );
    }

    @isTest
    private static void testMapUnmappedContacts() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        Account acc2 = new Account(Name = 'Test Employer 2', INT_OrganizationNumber__c = '8888888');
        insert acc;
        insert acc2;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Source__c = 'permittering',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;

        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '8888888',
                'test'
            )
        };
        List<Contact> existingContacts = SharedFunctions_FetchOrCreateContact.getExistingContacts(
            wrapperList
        );
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(
            new List<String>{ acc.INT_OrganizationNumber__c, acc2.INT_OrganizationNumber__c }
        );

        Integer contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(
            1,
            contactRelationships,
            'Should have added the contact to the existing accounts as a relationship'
        );

        Test.StartTest();
        SharedFunctions_FetchOrCreateContact.mapUnmappedContacts(
            wrapperList,
            existingContacts,
            accountMap
        );
        Test.StopTest();

        contactRelationships = [SELECT Id FROM AccountContactRelation].size();
        System.assertEquals(
            2,
            contactRelationships,
            'Should have added the contact to the new accounts as a relationship'
        );
    }

    @isTest
    private static void testCheckIfValidEmail_false() {
        Test.StartTest();
        Boolean actual1 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail(
            'test @domain.com'
        );
        Boolean actual2 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail(
            'testÆØÅ@domain.com'
        );
        Boolean actual3 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail('test@domaincom');
        Boolean actual4 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail(
            'te@st@domain.com'
        );
        Boolean actual5 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail('test@domain');
        Boolean actual6 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail(
            'test£@domain.com'
        );
        Boolean actual7 = SharedFunctions_FetchOrCreateContact.checkIfValidEmail('test@domain.com');
        Test.StopTest();

        System.assert(!actual1, 'should be false, as "test @domain.com" is wrong');
        System.assert(!actual2, 'should be false, as "testÆØÅ@domain.com" is wrong');
        System.assert(!actual3, 'should be false, as "test@domaincom" is wrong');
        System.assert(!actual4, 'should be false, as "te@st@domain.com" is wrong');
        System.assert(!actual5, 'should be false, as "test@domain" is wrong');
        System.assert(!actual6, 'should be false, as "test£@domain.com" is wrong');
        System.assert(actual7, 'should be true, as "test@domain.com" is correct');
    }

    @isTest
    private static void testCreateMapOfContactWrapper() {
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '8888888',
                'test'
            )
        };

        Test.StartTest();
        Map<String, List<SharedFunctions_ContactModel>> actual = SharedFunctions_FetchOrCreateContact.createMapOfContactWrapper(
            wrapperList
        );
        Test.StopTest();

        System.assertEquals(1, actual.size(), 'size should 1 one as only one contact');
        System.assert(
            actual.containsKey('test@domain.com'),
            'should contain key "test@domain.com"'
        );
    }

    @isTest
    private static void testCreateContactMapWithEmailAsKey() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Source__c = 'permittering',
            Email = 'test@domain.com',
            AccountId = acc.Id
        );
        insert con;

        Test.StartTest();
        Map<String, Contact> actual = SharedFunctions_FetchOrCreateContact.createContactMapWithEmailAsKey(
            new List<Contact>{ con }
        );
        Test.StopTest();

        System.assertEquals(1, actual.size(), 'size should be 1 contact');
        System.assert(
            actual.containsKey('test@domain.com'),
            'should contain key "test@domain.com"'
        );
        System.assertEquals(con.Id, actual.get('test@domain.com').Id, 'should be same contact id');
    }

    @isTest
    private static void testCreateRemainingContacts() {
        Account acc = new Account(Name = 'Test Employer 1', INT_OrganizationNumber__c = '99999999');
        insert acc;
        List<SharedFunctions_ContactModel> wrapperList = new List<SharedFunctions_ContactModel>{
            new SharedFunctions_ContactModel(
                'test',
                'etternavn',
                '90080900',
                'test@domain.com',
                '99999999',
                'test'
            )
        };
        Map<String, Contact> contactMap = SharedFunctions_FetchOrCreateContact.createContactMapWithEmailAsKey(
            new List<Contact>()
        );
        Map<String, Account> accountMap = SharedFunctions.fetchAccounts(
            new List<String>{ acc.INT_OrganizationNumber__c }
        );

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'Before, zero contacts');

        Test.StartTest();
        SharedFunctions_FetchOrCreateContact.createRemainingContacts(
            wrapperList,
            accountMap,
            contactMap
        );
        Test.StopTest();

        contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'After, one contact');
    }
}
