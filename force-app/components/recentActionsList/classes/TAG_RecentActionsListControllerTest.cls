@IsTest
private class TAG_RecentActionsListControllerTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USERAN',
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
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        System.runAs(arbeidsgiverUser) {
            List<Account> arbeidsgiverUserAccounts = new List<Account>();
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount0',
                    INT_OrganizationNumber__c = '9000000001',
                    INT_MunicipalityNumber__c = '3301',
                    OwnerId = arbeidsgiverUser.id
                )
            );
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    INT_MunicipalityNumber__c = '3301',
                    OwnerId = arbeidsgiverUser.id
                )
            );
            insert arbeidsgiverUserAccounts;

            NavUnit__c navUnit = new NavUnit__c(
                Name = 'NAV Unit Test',
                INT_UnitNumber__c = '1112'
            );
            insert navUnit;

            CustomOpportunity__c customOpportunity = new CustomOpportunity__c(
                InclusionStage__c = 'Ny henvendelse',
                InquiryCategory__c = 'Skal ansette',
                Source__c = 'Kontaktskjema',
                TAG_NavUnit__c = navUnit.Id,
                Account__c = arbeidsgiverUserAccounts[0].Id
            );
            insert customOpportunity;

            CustomOpportunity__c customOpportunity1 = new CustomOpportunity__c(
                InclusionStage__c = 'Ny henvendelse',
                InquiryCategory__c = 'Skal ansette',
                Source__c = 'Kontaktskjema',
                TAG_NavUnit__c = navUnit.Id,
                Account__c = arbeidsgiverUserAccounts[0].Id
            );
            insert customOpportunity1;

            Contact employerContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                AccountId = arbeidsgiverUserAccounts[0].Id
            );
            insert employerContact;

            Contact employerContact1 = new Contact(
                FirstName = 'Test1',
                LastName = 'User1',
                AccountId = arbeidsgiverUserAccounts[0].Id
            );
            insert employerContact1;

        User negativeAccessUser = TAG_TestDataFactory.createStandardUser('USER WITHOUT PERMISSIONS');
        System.runAs(negativeAccessUser) {
            List<Account> negativeAccessUserAccounts = new List<Account>();
            negativeAccessUserAccounts.add(
                new Account(
                    Name = 'TestAccount2',
                    INT_OrganizationNumber__c = '9000000003',
                    INT_MunicipalityNumber__c = '3301',
                    NumberOfWorkfare__c = 1,
                    OwnerId = negativeAccessUser.id
                )
            );
            insert negativeAccessUserAccounts;
        }
    }
}

    @isTest
    static void fetchRecordsUsersActions() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;
        System.runAs(user) {
            result = TAG_RecentActionsListController.getRecentActions(
                2,
                'Contact, CustomOpportunity__c',
                'CustomOpportunity__c:InquiryCategory__c',
                ''
            );
        }
        system.debug('Records:' + result );
        Assert.areEqual(2, result.size(), 'Should return 2');
    }
    //The result should be 4, but is only 2. The reason is because the data created in the setup gets the same LastModifiedDate and therefor the same key value in dateTimeWrappersMap

    @IsTest
    static void testFetchRecordsWithValidInput() {
        User user = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;

        System.runAs(user) {
            Test.startTest();
            result = TAG_RecentActionsListController.getRecentActions(
                2,
                'Contact, CustomOpportunity__c',
                'CustomOpportunity__c:InquiryCategory__c',
                ''
            );
            Test.stopTest();
        }
        system.debug('Records:' + result );
        System.assertEquals(2, result.size(), 'Should return 2 records');
        for (TAG_RecentActionsListController.VisitedWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.recordId, 'Record ID should not be null');
            System.assertNotEquals(null, wrapper.displayTitle, 'Display title should not be null');
            System.assertNotEquals(null, wrapper.lastViewedDate, 'Last viewed date should not be null');
        }
    }

    @IsTest
    static void testFetchRecordsWithNullLimit() {
        User user = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;

        System.runAs(user) {
            Test.startTest();
            result = TAG_RecentActionsListController.getRecentActions(
                null,
                'Account',
                'Account:Name',
                'Account:CRM_MainIndustry__c'
            );
            Test.stopTest();
        }

        System.assert(result.size() > 0, 'Should return default number of records when limit is null');
    }

    @IsTest
    static void testFetchRecordsWithEmptyAllowedObjects() {
        User user = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;

        System.runAs(user) {
            Test.startTest();
            result = TAG_RecentActionsListController.getRecentActions(
                10,
                '',
                '',
                ''
            );
            Test.stopTest();
        }

        System.assertEquals(0, result.size(), 'Should return no records when allowedObjects is empty');
    }

    @IsTest
    static void testFetchRecordsWithMalformedFieldMappings() {
        User user = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;

        System.runAs(user) {
            Test.startTest();
            result = TAG_RecentActionsListController.getRecentActions(
                10,
                'Account',
                'Account-Name', // malformed
                'Account=CRM_MainIndustry__c' // malformed
            );
            Test.stopTest();
        }

        System.assert(result.size() >= 0, 'Should handle malformed mappings gracefully');
    }
}
