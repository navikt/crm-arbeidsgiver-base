@isTest
private class BadgeControllerTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'ArbeidsgiverStillinger'
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
                    TAG_Category__c = 'Markedssamarbeid',
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
        }
    }

    @isTest
    static void testGetBadgeSettings() {
        Assert.isNotNull(BadgeController.getSettings('muligheter'), 'Result should not be null for valid badge key');
        Assert.isNull(BadgeController.getSettings('xxx'), 'Result should be null for bad key');
        Assert.isNull(BadgeController.getSettings(null), 'Result should be null for bad key');
    }

    @isTest
    static void testBadgeCreateRequest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<BadgeService.Badge> badges;
        System.runAs(user) {
            badges = BadgeController.createBadges(testAccount.id, 'muligheter,markedssamarbeid');
        }
        Assert.isFalse(badges.isEmpty(), 'Badges should be returned');
        Assert.areEqual(2, badges.size(), 'Should contain 2 badges');
    }

    @isTest
    static void testBadgeCreateRequestWithBadInput() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        Assert.areEqual(
            new List<BadgeService.Badge>(),
            BadgeController.createBadges(testAccount.id, 'bad data,markedssamarbeid'),
            'No badges should be returned'
        );
        Assert.areEqual(
            new List<BadgeService.Badge>(),
            BadgeController.createBadges(null, 'bad data,markedssamarbeid'),
            'No badges should be returned'
        );
        Assert.areEqual(
            new List<BadgeService.Badge>(),
            BadgeController.createBadges(testAccount.id, ''),
            'No badges should be returned'
        );
    }

    @isTest
    static void testGetRecords() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<BadgeService.Record> result;
        System.runAs(user) {
            result = BadgeController.getRecords(testAccount.Id, 'muligheter');
        }
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.isEmpty(), 'Records should be returned');
    }

    @isTest
    static void shouldFilterBadgesAccordingToFLS() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        List<BadgeService.Badge> badges;
        List<BadgeService.Record> records;
        // Create record with no access for test user
        List<Workfare__c> workfares = new List<Workfare__c>();
        workfares.add(
            new Workfare__c(
                Account__c = testAccount.Id,
                Name = '1234',
                StartDate__c = Date.today(),
                EndDate__c = Date.today().addDays(30),
                Status__c = 'GJENNOMFØRES',
                Type__c = 'MENTOR',
                NavIdent__c = 'C4567'
            )
        );
        insert workfares;
        System.runAs(user) {
            badges = BadgeController.createBadges(testAccount.id, 'muligheter,markedssamarbeid, tiltak, stillinger');
            records = BadgeController.getRecords(testAccount.Id, 'tiltak');
        }
        Assert.areEqual(3, badges.size(), 'Badges should be returned for accesible objects');
        Assert.isNull(records, 'Records should not be returned');
    }
}
