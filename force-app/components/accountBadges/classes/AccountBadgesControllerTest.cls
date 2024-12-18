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
                    TAG_Partner_Status__c = 'Strategisk partner'
                )
            );
            testAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    TAG_Partner_Status__c = null
                )
            );
            insert testAccounts;

            TAG_TestDataFactory.createUserWithPermset('ARBEIDSGIVER USER', 'Arbeidsgiver_base');
            TAG_TestDataFactory.createStandardUser('USER WITHOUT PERMISSIONS');
        }

    }

    @isTest
    static void badges_Should_Be_Created_When_Account_Match_Criteria() {
        Account testAccount = [
            SELECT Id, TAG_Partner_Status__c
            FROM Account
            WHERE TAG_Partner_Status__c = 'Strategisk partner'
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
        Assert.isTrue(accountBadges.size() == 1, 'Badges should be returned');
        Assert.areEqual(
            testAccount.TAG_Partner_Status__c,
            accountBadges[0].label,
            'Label should be same as account partner status'
        );
    }

    @isTest
    static void no_Badges_Should_Be_Created_When_Account_Match_No_Criteria() {
        Account testAccount = [
            SELECT Id, TAG_Partner_Status__c
            FROM Account
            WHERE TAG_Partner_Status__c = NULL
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
        Assert.isTrue(accountBadges.size() == 0, 'Badges should not have any items');
    }

    @isTest
    static void badge_Should_Not_Be_Created_For_Non_Accessible_Fields() {
        Account testAccount = [
            SELECT Id, TAG_Partner_Status__c
            FROM Account
            WHERE TAG_Partner_Status__c = 'Strategisk partner'
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

        Assert.isNotNull(accountBadges, 'Badges should be returned');
        Assert.isTrue(accountBadges.size() == 0, 'Badges should not have any items');
    }
}
