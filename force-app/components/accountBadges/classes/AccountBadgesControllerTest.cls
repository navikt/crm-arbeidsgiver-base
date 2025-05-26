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

            Contact employerContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                AccountId = arbeidsgiverUserAccounts[0].Id
            );
            insert employerContact;
            // Create employer agreements
            List<Contract__c> employerAgreements = new List<Contract__c>();
            employerAgreements.add(
                new Contract__c(
                    TAG_Account__c = arbeidsgiverUserAccounts[0].Id,
                    TAG_Category__c = 'Marked-samarbeid',
                    TAG_StartDate__c = Date.today(),
                    TAG_EndDate__c = Date.today().addDays(30),
                    TAG_Status__c = 'Godkjent',
                    TAG_Description__c = 'test',
                    TAG_Contact__c = employerContact.Id,
                    TAG_InternalContact__c = arbeidsgiverUser.Id,
                    TAG_ExternalURL__c = 'www.example.com',
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
            insert workfares;
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
    static void fetchRecordsWithValidParameters() {
        //List<sObject> fetchRecords(Id accountId, String objectName)
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<sObject> result;
        System.runAs(user) {
            result = AccountBadgesController.fetchRecords(testAccount.Id, 'Workfare__c');
        }

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() == 1, 'Result should contain records');
        Assert.isInstanceOfType(result[0], Workfare__c.class, 'Result should be of type Workfare__c');
    }

    @isTest
    static void fetchRecordsWhenNoRecordsExists() {
        //List<sObject> fetchRecords(Id accountId, String objectName)
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount1' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<sObject> result;
        System.runAs(user) {
            result = AccountBadgesController.fetchRecords(testAccount.Id, 'Workfare__c');
        }
        Assert.isTrue(result.size() == 0, 'Result should not contain records');
    }

    @isTest
    static void fetchRecordsWhenNoAccess() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<Workfare__c> employerWorkfares;
        System.runAs(user) {
            Test.startTest();
            employerWorkfares = (List<Workfare__c>) AccountBadgesController.fetchRecords(testAccount.Id, 'Workfare__c');
            Test.stopTest();
        }
        Assert.isTrue(employerWorkfares.size() == 0, 'Result should not contain records');
    }

    @isTest
    static void createBadgeFromConfig() {
        // 'Muligheter({0})' og  'url' => '/lightning/r/Report/{0}/view?fv0={1}',
        AccountBadgesController.Badge opportunityBadge = AccountBadgesController.createBadgeFromConfig(
            'Muligheter',
            new List<Object>{ 10 },
            new List<Object>{ '00O0E000001lLPaUAM', '0010E00000iiinlQAA' }
        );
        Assert.areEqual('Muligheter(10)', opportunityBadge.label);
        Assert.areEqual(
            '/lightning/r/Report/00O0E000001lLPaUAM/view?fv0=0010E00000iiinlQAA&fv2=',
            opportunityBadge.url
        );
        Assert.areEqual('Muligheter', opportunityBadge.badgeType);
        Assert.areEqual(
            'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".',
            opportunityBadge.helpText
        );
    }

    @isTest
    static void badgesShouldBeCreatedWhenAccountMatchCriteria() {
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
        Assert.areEqual(5, accountBadges.size(), 'Expected 5 badges to be created');
        Assert.isTrue(badgeMap.containsKey('Marked-samarbeid'), 'Should contain badge for agreement Marked-samarbeid');
        Assert.isTrue(badgeMap.containsKey('Muligheter(15)'), 'Should contain badge for number of opportunities');
        Assert.isTrue(badgeMap.containsKey('IA-samarbeid'), 'Should contain badge for number of ia-cooperations');
        Assert.isTrue(badgeMap.containsKey('Stillinger(2)'), 'Should contain badge for number of job postings');
        Assert.isTrue(badgeMap.containsKey('Tiltak(1)'), 'Should contain badge for number of workfare');
    }

    @isTest
    static void badgesShouldNotBeCreatedWhenNoData() {
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
    static void badgeShouldNotBeCreatedForNonAccessibleAccountFields() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'TestAccount0'
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
    static void errorStatesShouldBeHandeledOrLogged() {
        List<AccountBadgesController.Badge> accountBadges = AccountBadgesController.createBadges(null);
        Assert.areEqual(0, accountBadges.size(), 'Should return empty list on error.');
    }
}
