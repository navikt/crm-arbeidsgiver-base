@isTest
private class AccountBadgesControllerTest {
    @testSetup
    private static void setup() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User thisUser = new User(
            LastName = 'user',
            Email = 'user@nav.apextest',
            Username = 'user@nav.apextest',
            Alias = 'usr',
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );
        insert thisUser;

        System.runAs(thisUser) {
            List<Account> testAccounts = new List<Account>();
            testAccounts.add(
                new Account(
                    Name = 'TestAccount0',
                    INT_OrganizationNumber__c = '9000000001',
                    TAG_Partner_Status__c = 'Strategisk Partner',
                    TAG_FiaCaseStatus__c = 'VI_BISTÅR',
                    NumberOfWorkfare__c = 5
                )
            );
            testAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    TAG_Partner_Status__c = null,
                    TAG_FiaCaseStatus__c = null,
                    NumberOfWorkfare__c = 0
                )
            );
            insert testAccounts;

            List<CustomOpportunity__c> testOpportunities = TAG_TestDataFactory.getCustomOpportunities(200, false);
            Integer i = 0;
            for (CustomOpportunity__c opp : testOpportunities) {
                opp.Account__c = testAccounts[1].Id;
                if (i < 50) {
                    opp.InclusionStage__c = 'Ny henvendelse';
                    opp.InquiryCategory__c = 'Skal ansette';
                } else if (i < 100) {
                    opp.InclusionStage__c = 'Utforskes';
                    opp.InquiryCategory__c = 'Forebygge sykefravær';
                } else if (i < 150) {
                    opp.InclusionStage__c = 'Åpen for kandidater';
                    opp.InquiryCategory__c = 'Skal ansette';
                } else {
                    opp.InclusionStage__c = 'Avsluttet';
                    opp.InquiryCategory__c = 'Tiltak';
                    opp.Result__c = 'Arbeidstrening';
                }
                i++;
            }
            insert testOpportunities;

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
            User user1 = [SELECT id FROM User WHERE LastName = 'Arbeidsgiver USER' LIMIT 1];
            User user2 = TAG_TestDataFactory.createStandardUser('USER WITHOUT PERMISSIONS');
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
        User user = [SELECT id FROM User WHERE LastName = 'Arbeidsgiver USER' LIMIT 1];
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
            testAccount.NumberOfWorkfare__c + ' aktive tiltak',
            accountBadges[2].label,
            'Label should be same as account number of workfare'
        );

        Assert.areEqual(
            '0 åpne muligheter',
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
        User user = [SELECT id FROM User WHERE LastName = 'Arbeidsgiver USER' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.isNotNull(accountBadges, 'Badges should be returned');

        Assert.areEqual(
            testAccount.NumberOfWorkfare__c + ' aktive tiltak',
            accountBadges[0].label,
            'Label should be same as account number of workfare'
        );
        Assert.areEqual(
            '150 åpne muligheter',
            accountBadges[1].label,
            'Label should be same as number of open opportunities'
        );
        Assert.areEqual(
            '50 nye henvendelser',
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
            WHERE Name = 'TestAccount0'
            LIMIT 1
        ];
        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Assert.isTrue(AccessControlValidator.sObjectIsAccessible('Account'));
            Assert.isFalse(AccessControlValidator.fieldIsAccessible('Account', 'TAG_Partner_Status__c'));

            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.isTrue(accountBadges.size() == 0, 'Badges should not have any items');
    }
    @isTest
    static void badge_Should_Not_Be_Created_For_Non_Accessible_Opportunity_Fields() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'TestAccount1'
            LIMIT 1
        ];
        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<AccountBadgesController.Badge> accountBadges;
        System.runAs(user) {
            Assert.isTrue(AccessControlValidator.sObjectIsAccessible('Account'));
            Assert.isFalse(AccessControlValidator.sObjectIsAccessible('CustomOpportunity__c'));

            Test.startTest();
            accountBadges = AccountBadgesController.createBadges(testAccount.Id);
            Test.stopTest();
        }
        Assert.isTrue(accountBadges.size() == 0, 'Badges should not have any items');
    }

    @isTest
    static void error_States_Should_Be_Handeled_Or_Logged() {
        List<AccountBadgesController.Badge> accountBadges = AccountBadgesController.createBadges(null);
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list on error.');
    }
}
