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
                20,
                false
            );
            Integer i = 0;
            for (CustomOpportunity__c opp : arbeidsgiverUserOpportunities) {
                opp.Account__c = arbeidsgiverUserAccounts[0].Id;
                opp.OwnerId = arbeidsgiverUser.id;
                if (i < 5) {
                    opp.InclusionStage__c = 'Ny henvendelse';
                    opp.InquiryCategory__c = 'Skal ansette';
                } else if (i < 10) {
                    opp.InclusionStage__c = 'Utforskes';
                    opp.InquiryCategory__c = 'Forebygge sykefravær';
                } else if (i < 15) {
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

            // Create employer agreements
            List<Contract__c> employerAgreements = new List<Contract__c>();
            employerAgreements.add(
                new Contract__c(
                    TAG_Account__c = arbeidsgiverUserAccounts[0].Id,
                    TAG_Category__c = 'Inkluderingsavtale (Arbeidsgiver)',
                    TAG_StartDate__c = Date.today(),
                    TAG_EndDate__c = Date.today().addDays(30),
                    TAG_Status__c = 'Godkjent',
                    Region__c = 'Regional',
                    TAG_Type_Partner__c = 'Strategisk Partner',
                    RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
                        .get('EmployerAgreement')
                        .getRecordTypeId()
                )
            );

            insert employerAgreements;

            // Create IA-sak record
            IACase__c iaCase = new IACase__c(Name = 'ABCDEFGHT', CaseStatus__c = 'VI_BISTÅR');
            insert iaCase;
            // Create IA-samarbeid record
            List<IACooperation__c> iaCooperations = new List<IACooperation__c>();
            iaCooperations.add(
                new IACooperation__c(
                    Account__c = arbeidsgiverUserAccounts[0].Id,
                    CooperationId__c = '1234',
                    StartDate__c = Date.today(),
                    EndDate__c = Date.today().addDays(30),
                    Status__c = 'AKTIV',
                    IACase__c = iaCase.id
                )
            );

            insert iaCooperations;

            // Create Job postings record
            List<JobPosting__c> jobPostings = new List<JobPosting__c>();
            jobPostings.add(
                new JobPosting__c(
                    Account__c = arbeidsgiverUserAccounts[0].Id,
                    Published__c = Date.today(),
                    Expires__c = Date.today().addDays(30),
                    Status__c = 'ACTIVE',
                    Title__c = 'Test 1'
                )
            );
            jobPostings.add(
                new JobPosting__c(
                    Account__c = arbeidsgiverUserAccounts[0].Id,
                    Published__c = Date.today(),
                    Expires__c = Date.today().addDays(30),
                    Status__c = 'ACTIVE',
                    Title__c = 'Test 2'
                )
            );

            insert jobPostings;

            // Create Workfare record
            List<Workfare__c> workfares = new List<Workfare__c>();
            workfares.add(
                new Workfare__c(
                    Account__c = arbeidsgiverUserAccounts[0].Id,
                    Name = '1234',
                    StartDate__c = Date.today(),
                    EndDate__c = Date.today().addDays(30),
                    Status__c = 'GJENNOMFØRES',
                    Type__c = 'MENTOR',
                    NavIdent__c = 'C4567'
                )
            );
        }

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

    @isTest
    static void badges_Should_Be_Created_When_Account_Match_Criteria() {
        Account testAccount = [
            SELECT Id, TAG_Partner_Status__c, NumberOfWorkfare__c
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

        // Assertions
        Map<String, AccountBadgesController.Badge> badgeMap = new Map<String, AccountBadgesController.Badge>();
        for (AccountBadgesController.Badge badge : accountBadges) {
            badgeMap.put(badge.label, badge);
        }
        Assert.isTrue(
            badgeMap.containsKey('Regional inkluderingsavtale'),
            'Should contain badge for agreement region+category'
        );
        Assert.isTrue(badgeMap.containsKey('Strategisk partner'), 'Should contain badge for partner type');
        //Assert.isTrue(badgeMap.containsKey('Aktive tiltak(5)'), 'Should contain badge for number of active workfare');
        Assert.isTrue(badgeMap.containsKey('Muligheter(15)'), 'Should contain badge for number of opportunities');
        Assert.isTrue(badgeMap.containsKey('IA-samarbeid(1)'), 'Should contain badge for number of ia-cooperations');
        Assert.isTrue(badgeMap.containsKey('Stillinger(2)'), 'Should contain badge for number of job postings');
        Assert.isTrue(badgeMap.containsKey('Tiltak(1)'), 'Should contain badge for number of workfare');
        Assert.areEqual(6, accountBadges.size(), 'Expected 6 badges to be created');
    }

    @isTest
    static void badges_Should_Not_Be_Created_When_No_Data() {
        Account testAccount = [
            SELECT Id
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
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list of badges');
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
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list of badges');
    }

    @isTest
    static void error_States_Should_Be_Handeled_Or_Logged() {
        List<AccountBadgesController.Badge> accountBadges = AccountBadgesController.createBadges(null);
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list on error.');
    }
}
