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
    static void fetchRecordsUsersActions() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;
        System.runAs(user) {
            result = TAG_RecentActionsListController.getRecentActions(10, 'Contact, Account, CustomOpportunity__c', 'CustomOpportunity__c:InquiryCategory__c;JobPosting__c:Title__c;ArenaActivity__c:Aktivitetstype__c;Workfare__c:Type__c;CustomCampaignMember__c:Campaign_type__c;Contract__c:TAG_Category__c', 'JobPosting__c:Account__r.Name;Account:CRM_MainIndustry__c;Contact:Title;CustomOpportunity__c:Account__r.Name;IACooperation__c:Account__r.Name;AccountTeamMember:TeamMemberRole;ArenaActivity__c:Account__r.Name;Workfare__c:Account__r.Name;CustomCampaignMember__c:Account__r.Name;DialogueMeeting__c:Account__r.Name;Contract__c:TAG_Account__r.Name');
        }
        system.debug('Records:' + result );
        Assert.areEqual(10, result.size(), 'Should return 10');
    }

    @IsTest
    static void testFetchRecordsWithValidInput() {
        User user = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USERAN' LIMIT 1];
        List<TAG_RecentActionsListController.VisitedWrapper> result;

        System.runAs(user) {
            Test.startTest();
            result = TAG_RecentActionsListController.getRecentActions(
                10,
                'Contact, CustomOpportunity__c',
                'CustomOpportunity__c:InquiryCategory__c;JobPosting__c:Title__c',
                'JobPosting__c:Account__r.Name;Account:CRM_MainIndustry__c;Contact:Title'
            );
            Test.stopTest();
        }
        system.debug('Records:' + result );
        System.assertEquals(10, result.size(), 'Should return 10 records');
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
