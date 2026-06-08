@isTest
private class TAG_RelatedListControllerTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{
                'Arbeidsgiver_arenaActivity',
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'Arbeidsgiver_IA',
                'ArbeidsgiverStillinger',
                'Arbeidsgiver_Workfare'
            }
        );
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        System.runAs(arbeidsgiverUser) {
            List<Account> arbeidsgiverUserAccounts = new List<Account>();
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount0',
                    INT_OrganizationNumber__c = '9000000001',
                    INT_MunicipalityNumber__c = '3301',
                    NumberOfWorkfare__c = 5,
                    OwnerId = arbeidsgiverUser.id
                )
            );
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    INT_MunicipalityNumber__c = '3301',
                    TAG_Partner_Status__c = null,
                    NumberOfWorkfare__c = 0,
                    OwnerId = arbeidsgiverUser.id
                )
            );
            insert arbeidsgiverUserAccounts;

            List<CustomOpportunity__c> arbeidsgiverUserOpportunities = TAG_TestDataFactory.getCustomOpportunities(
                3,
                false
            );
            Integer i = 0;
            for (CustomOpportunity__c opp : arbeidsgiverUserOpportunities) {
                opp.Account__c = arbeidsgiverUserAccounts[0].Id;
                opp.OwnerId = arbeidsgiverUser.id;
                opp.InclusionStage__c = 'Ny henvendelse';
                opp.InquiryCategory__c = 'Skal ansette';
            }
            insert arbeidsgiverUserOpportunities;

            Contact con = new Contact(
                TAG_Informed__c = true,
                LastName = 'test',
                FirstName = 'test',
                Source__c = 'Permittering',
                Email = 'test@domain.com',
                AccountId = arbeidsgiverUserAccounts[0].Id
            );
            insert con;
        }
    }

    @isTest
    static void testGetRelatedList_ReturnContacts() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        List<String> fieldNames = new List<String>{ 'Id', 'FirstName', 'LastName', 'TAG_Informed__c', 'AccountId' };
        Id parentId = acct.Id;
        String objectApiName = 'Contact';
        String relationField = 'AccountId';
        String filterConditions = 'TAG_Informed__c = true';

        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<SObject> results;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            results = TAG_RelatedListController.getRelatedList(
                fieldNames,
                parentId,
                objectApiName,
                relationField,
                filterConditions
            );
            Test.stopTest();
        }
        System.assertEquals(1, results.size(), 'Expected exactly one Contact under TestAccount0.');

        Contact fetchedCon = (Contact) results[0];
        System.assertEquals('test', fetchedCon.FirstName, 'FirstName should be "test"');
        System.assertEquals('test', fetchedCon.LastName, 'LastName should be "test"');
        System.assertEquals(
            true,
            fetchedCon.TAG_Informed__c,
            'TAG_Informed__c should be true for the returned record.'
        );
        System.assertEquals(
            acct.Id,
            fetchedCon.AccountId,
            'AccountId on the returned Contact should match TestAccount0.Id.'
        );
    }
    @isTest
    static void testGetRelatedList_ReturnCustomOpportunities() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        List<String> fieldNames = new List<String>{
            'Id',
            'Name',
            'InclusionStage__c',
            'InquiryCategory__c',
            'Account__c'
        };
        Id parentId = acct.Id;
        String objectApiName = 'CustomOpportunity__c';
        String relationField = 'Account__c';
        String filterConditions = 'InquiryCategory__c = \'Skal ansette\'';

        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<SObject> oppResults;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            oppResults = TAG_RelatedListController.getRelatedList(
                fieldNames,
                parentId,
                objectApiName,
                relationField,
                filterConditions
            );
            Test.stopTest();
        }
        System.assertEquals(
            3,
            oppResults.size(),
            'Expected three CustomOpportunity__c records with InquiryCategory__c = "Skal ansette" under TestAccount0.'
        );

        for (SObject sobj : oppResults) {
            CustomOpportunity__c fetchedOpp = (CustomOpportunity__c) sobj;
            System.assertEquals(
                'Skal ansette',
                fetchedOpp.InquiryCategory__c,
                'Each returned CustomOpportunity__c record should have InquiryCategory__c = "Skal ansette".'
            );
            System.assertEquals(
                acct.Id,
                fetchedOpp.Account__c,
                'Each returned CustomOpportunity__c should refer to the same Account (TestAccount0).'
            );
        }
    }

    @isTest
    static void testGetRelatedList_NoFilter_ReturnsAllChildren() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<SObject> results;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            results = TAG_RelatedListController.getRelatedList(
                new List<String>{ 'Id', 'Name', 'Account__c' },
                acct.Id,
                'CustomOpportunity__c',
                'Account__c',
                null
            );
            Test.stopTest();
        }
        System.assertEquals(
            3,
            results.size(),
            'When no filter is provided, all CustomOpportunity__c under the parent should be returned.'
        );
    }

    @isTest
    static void testGetRelatedList_Bulk() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(LastName = 'Bulk' + i, AccountId = acct.Id, TAG_Informed__c = true));
        }
        insert bulkContacts;

        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<SObject> results;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            results = TAG_RelatedListController.getRelatedList(
                new List<String>{ 'Id', 'LastName', 'AccountId' },
                acct.Id,
                'Contact',
                'AccountId',
                'TAG_Informed__c = true'
            );
            Test.stopTest();
        }
        System.assertEquals(201, results.size(), 'Expected all bulk-inserted contacts to be returned.');
    }

    @isTest
    static void testGetRelatedList_InvalidFilterFormat_Throws() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        Map<String, String> invalidFilters = new Map<String, String>{
            // Sammensatte uttrykk støttes ikke (én betingelse per filter).
            'Id != null OR Name LIKE \'%\'' => 'compound expression with OR',
            'TAG_Informed__c = true AND IsActive = true' => 'compound expression with AND',
            // Manglende deler.
            'TAG_Informed__c =' => 'missing value',
            '= true' => 'missing field',
            // Ugyldig operator (== finnes ikke i SOQL).
            'TAG_Informed__c == true' => 'invalid operator',
            // Parenteser er ikke i whitelisten.
            '(TAG_Informed__c = true)' => 'parentheses not allowed',
            // SQL-idiom som ikke gjelder SOQL — bør likevel avvises.
            'TAG_Informed__c = true; DELETE FROM Contact' => 'sql statement separator'
        };

        Test.startTest();
        for (String badFilter : invalidFilters.keySet()) {
            try {
                TAG_RelatedListController.getRelatedList(
                    new List<String>{ 'Id' },
                    acct.Id,
                    'Contact',
                    'AccountId',
                    badFilter
                );
                Assert.fail('Expected exception for filter with ' + invalidFilters.get(badFilter) + ': ' + badFilter);
            } catch (AuraHandledException e) {
                Assert.areEqual('Ugyldig filter-syntaks. Forventet: <felt> <operator> <verdi>', e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRelatedList_MissingParentId_Throws() {
        try {
            TAG_RelatedListController.getRelatedList(new List<String>{ 'Id' }, null, 'Contact', 'AccountId', null);
            Assert.fail('Forventet exception');
        } catch (AuraHandledException e) {
            Assert.areEqual('Manglende påkrevde parametere', e.getMessage());
        }
    }

    @isTest
    static void testGetRelatedList_EmptyFieldList_Throws() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        try {
            TAG_RelatedListController.getRelatedList(new List<String>(), acct.Id, 'Contact', 'AccountId', null);
            Assert.fail('Forventet exception');
        } catch (AuraHandledException e) {
            Assert.areEqual('Manglende påkrevde parametere', e.getMessage());
        }
    }

    @isTest
    static void testGetRelatedList_BlockedByFLS_Throws() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        List<String> fieldNames = new List<String>{ 'Id', 'FirstName', 'LastName', 'GenderIdentity' };
        Id parentId = acct.Id;
        String objectApiName = 'Contact';

        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<SObject> results;
        System.runAs(arbeidsgiverUser) {
            Assert.isFalse(
                Schema.sObjectType.Contact.fields.GenderIdentity.isAccessible(),
                'Test user should not have access to GenderIdentity field.'
            );
            Test.startTest();
            try {
                TAG_RelatedListController.getRelatedList(fieldNames, parentId, objectApiName, 'AccountId', null);
                Assert.fail('Expected exception due to FLS: GenderIdentity is not accessible to the running user.');
            } catch (AuraHandledException e) {
                Assert.areEqual(
                    'Du mangler tilgang til noen av feltene i relaterte poster. Kontakt administratoren for å få tilgang.',
                    e.getMessage()
                );
            }
            Test.stopTest();
        }
    }
}
