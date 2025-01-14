@isTest
private class AccountBadgesControllerTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{
                'Arbeidsgiver_arenaActivity',
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'Arbeidsgiver_IA'
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
                    TAG_Partner_Status__c = 'Strategisk Partner',
                    TAG_FiaCaseStatus__c = 'VI_BISTÅR',
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
                    TAG_FiaCaseStatus__c = null,
                    NumberOfWorkfare__c = 0,
                    OwnerId = arbeidsgiverUser.id
                )
            );
            insert arbeidsgiverUserAccounts;

            List<CustomOpportunity__c> arbeidsgiverUserOpportunities = TAG_TestDataFactory.getCustomOpportunities(
                200,
                false
            );
            Integer i = 0;
            for (CustomOpportunity__c opp : arbeidsgiverUserOpportunities) {
                opp.Account__c = arbeidsgiverUserAccounts[1].Id;
                opp.OwnerId = arbeidsgiverUser.id;
                if (i < 50) {
                    opp.InclusionStage__c = 'Ny henvendelse';
                    opp.InquiryCategory__c = 'Skal ansette';
                } else if (i < 100) {
                    opp.InclusionStage__c = 'Utforskes';
                    opp.InquiryCategory__c = 'Forebygge sykefravær';
                } else if (i < 150) {
                    opp.InclusionStage__c = 'Ferdig Avklart';
                    opp.InquiryCategory__c = 'Skal ansette';
                    opp.Result__c = 'Arbeidstrening';
                } else {
                    opp.InclusionStage__c = 'Avsluttet';
                    opp.InquiryCategory__c = 'Tiltak';
                    opp.Result__c = 'Arbeidstrening';
                }
                i++;
            }
            insert arbeidsgiverUserOpportunities;
        }

        User negativeAccessUser = TAG_TestDataFactory.createStandardUser('USER WITHOUT PERMISSIONS');
        System.runAs(negativeAccessUser) {
            List<Account> negativeAccessUserAccounts = new List<Account>();
            negativeAccessUserAccounts.add(
                new Account(
                    Name = 'TestAccount2',
                    INT_OrganizationNumber__c = '9000000003',
                    INT_MunicipalityNumber__c = '3301',
                    TAG_Partner_Status__c = 'Strategisk Partner',
                    TAG_FiaCaseStatus__c = 'VI_BISTÅR',
                    NumberOfWorkfare__c = 1,
                    OwnerId = negativeAccessUser.id
                )
            );
            insert negativeAccessUserAccounts;

            List<CustomOpportunity__c> negativeAccessUserOpportunities = TAG_TestDataFactory.getCustomOpportunities(
                1,
                false
            );
            negativeAccessUserOpportunities[0].Account__c = negativeAccessUserAccounts[0].Id;
            negativeAccessUserOpportunities[0].OwnerId = negativeAccessUser.id;
            negativeAccessUserOpportunities[0].InquiryCategory__c = 'Skal ansette';
            insert negativeAccessUserOpportunities;
        }
    }

    @isTest
    static void badges_Should_Be_Created_When_Account_Match_Criteria() {
        Account testAccount = [
            SELECT Id, TAG_Partner_Status__c, TAG_FiaCaseStatus__c, NumberOfWorkfare__c
            FROM Account
            WHERE Name = 'TestAccount0'
            LIMIT 1
        ];

        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.isNotNull(accountBadges, 'Badges should be returned');

        Assert.areEqual(
            testAccount.TAG_Partner_Status__c,
            accountBadges[0].label,
            'Label should be same as account partner status'
        );

        Assert.areEqual(
            testAccount.TAG_FiaCaseStatus__c,
            accountBadges[1].label,
            'Label should be same as account fia case status'
        );

        Assert.areEqual(
            'Aktive Tiltak: ' + testAccount.NumberOfWorkfare__c,
            accountBadges[2].label,
            'Label should be same as account number of workfare'
        );

        Assert.areEqual(
            'Åpne Muligheter: 0',
            accountBadges[3].label,
            'Badge should display 0 open opportunities when there are none'
        );

        Assert.areEqual(4, accountBadges.size(), 'Should not return more than expected number of badges');
    }

    @isTest
    static void badges_Should_Be_Created_When_Account_Has_Opportunities() {
        Account testAccount = [
            SELECT Id, NumberOfWorkfare__c
            FROM Account
            WHERE Name = 'TestAccount1'
            LIMIT 1
        ];

        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.isNotNull(accountBadges, 'Badges should be returned');

        Assert.areEqual(
            'Aktive Tiltak: ' + testAccount.NumberOfWorkfare__c,
            accountBadges[0].label,
            'Label should be same as account number of workfare'
        );
        Assert.areEqual(
            'Åpne Muligheter: 150',
            accountBadges[1].label,
            'Label should be same as number of open opportunities'
        );
        Assert.areEqual(
            'Ny Henvendelse!',
            accountBadges[2].label,
            'Label should be same as number of new opportunities'
        );
        Assert.areEqual(
            'Åpen for kandidater!',
            accountBadges[3].label,
            'Label should state that account is open for candidates'
        );

        Assert.areEqual(4, accountBadges.size(), 'Should not return more than expected number of badges');
    }

    @isTest
    static void badge_Should_Not_Be_Created_For_Non_Accessible_Account_Fields() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'TestAccount2'
            LIMIT 1
        ];

        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.areEqual(0, accountBadges.size(), 'Badges should not have any items');
    }

    @isTest
    static void badge_Should_Not_Be_Created_For_Non_Accessible_Opportunity_Fields() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'TestAccount2'
            LIMIT 1
        ];

        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.areEqual(0, accountBadges.size(), 'Badges should not have any items');
    }

    @isTest
    static void error_States_Should_Be_Handeled_Or_Logged() {
        List<AccountBadgesController.Badge> accountBadges = AccountBadgesController.createBadges(null);
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list on error.');
    }
}
