@IsTest(SeeAllData=false)
private class TAG_ContractMetricsBatchTest {
    private static final Date START_DATE = Date.newInstance(2026, 1, 10);
    private static final Date END_DATE = Date.newInstance(2026, 1, 20);
    private static Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();
    private static String contactId;

    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER ADMIN',
            new List<String>{ 'Arbeidsgiver_base', 'Arbeidsgiver_contract', 'Admin_Base' }
        );
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Account> accounts = new List<Account>{
                buildAccount('9000000001'),
                buildAccount('9000000002'),
                buildAccount('9000000003'),
                buildAccount('9000000004'),
                buildAccount('9000000005'),
                buildAccount('9000000006')
            };
            insert as system accounts;
            Account account1 = accounts[0]; // happy path
            Account account2 = accounts[1]; // has no meetings or candidate outcomes
            Account account3 = accounts[2]; // has overlaping contracts
            Account account4 = accounts[3]; // has no changes
            Account account5 = accounts[4]; // causes exception
            Account account6 = accounts[5]; // has 251 contracts

            Contact contactRecord = new Contact(LastName = 'Mandatory contract contact', AccountId = account1.Id);
            insert as system contactRecord;
            contactId = contactRecord.Id;

            List<Contract__c> contracts = new List<Contract__c>{
                buildContract(account1.Id, START_DATE, END_DATE, 'Godkjent', 9),
                buildContract(account2.Id, START_DATE, END_DATE, 'Godkjent', 4),
                buildContract(account3.Id, START_DATE, END_DATE, 'Godkjent', 0),
                buildContract(account3.Id, START_DATE.addDays(5), END_DATE.addDays(5), 'Godkjent', 0),
                buildContract(account4.Id, START_DATE, END_DATE, 'Utkast', 7),
                buildContract(account4.Id, START_DATE, END_DATE, 'Godkjent', 0),
                buildContract(account5.Id, START_DATE, END_DATE, 'Godkjent', 0)
            };
            for (Integer index = 0; index < 251; index++) {
                contracts.add(buildContract(account6.Id, START_DATE, END_DATE, 'Godkjent', 3));
            }
            insert as system contracts;
            insert as system new List<CandidateOutcome__c>{
                buildOutcome(account1.Id, 'PRESENTERT', START_DATE, 0, 0),
                buildOutcome(account1.Id, 'FATT_JOBBEN', END_DATE, 23, 59),
                buildOutcome(account1.Id, 'IKKE_PRESENTERT', START_DATE.addDays(1), 12, 0),
                buildOutcome(account1.Id, 'PRESENTERT', END_DATE.addDays(1), 0, 0),
                buildOutcome(account3.Id, 'PRESENTERT', START_DATE.addDays(2), 12, 0),
                buildOutcome(account3.Id, 'PRESENTERT', START_DATE.addDays(7), 12, 0),
                buildOutcome(account3.Id, 'FATT_JOBBEN', END_DATE.addDays(2), 12, 0),
                buildOutcome(account5.Id, 'PRESENTERT', START_DATE, 12, 0)
            };

            insert as system new List<Event>{
                buildMeeting(account1.Id, START_DATE, 'Jobbmesser og møteplass'),
                buildMeeting(account1.Id, END_DATE, 'Jobbmesser og møteplass'),
                buildMeeting(account1.Id, END_DATE, 'IPS Jobbutvikling')
            };
        }
    }

    @IsTest
    static void shouldCalculateAllMetricsAndIgnoreExcludedRecords() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> scope = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000001'
            ];
            Test.startTest();
            TAG_ContractMetricsService.applyChanges(scope);
            Test.stopTest();

            Contract__c actual = [
                SELECT Id, TAG_NumberOfPresentedCandidates__c, TAG_NumberOfHiredCandidates__c, TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000001'
                LIMIT 1
            ];
            Assert.areEqual(2, actual.TAG_NumberOfMeetings__c, 'Both boundary meetings must be included');
            Assert.areEqual(1, actual.TAG_NumberOfPresentedCandidates__c, 'Only one presented outcome is in range');
            Assert.areEqual(1, actual.TAG_NumberOfHiredCandidates__c, 'The end-date outcome must be included');
        }
    }

    @IsTest
    static void shouldSetMetricsToZeroWhenNoMatchesExist() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> scope = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000002'
            ];
            Test.startTest();
            TAG_ContractMetricsService.applyChanges(scope);
            Test.stopTest();

            Contract__c actual = [
                SELECT Id, TAG_NumberOfPresentedCandidates__c, TAG_NumberOfHiredCandidates__c, TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000002'
                LIMIT 1
            ];
            Assert.areEqual(0, actual.TAG_NumberOfPresentedCandidates__c, 'Presented count must be reset');
            Assert.areEqual(0, actual.TAG_NumberOfHiredCandidates__c, 'Hired count must be reset');
            Assert.areEqual(0, actual.TAG_NumberOfMeetings__c, 'Meeting count must be reset');
        }
    }

    @IsTest
    static void shouldHandleOverlappingContractsOnSameAccount() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> scope = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000003'
            ];
            Test.startTest();
            TAG_ContractMetricsService.applyChanges(scope);
            Test.stopTest();

            List<Contract__c> contracts = [
                SELECT TAG_NumberOfHiredCandidates__c, TAG_NumberOfPresentedCandidates__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000003'
                ORDER BY TAG_StartDate__c ASC
            ];
            Assert.areEqual(
                2,
                contracts.get(0).TAG_NumberOfPresentedCandidates__c,
                'First contract must count both presented outcomes'
            );
            Assert.areEqual(
                1,
                contracts.get(1).TAG_NumberOfPresentedCandidates__c,
                'Second contract must count only its presented outcome'
            );
            Assert.areEqual(
                1,
                contracts.get(1).TAG_NumberOfHiredCandidates__c,
                'Second contract must count its hired outcome'
            );
        }
    }

    @IsTest
    static void shouldReturnWithoutSavingWhenNoChangesExist() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> scope = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000004'
            ];

            Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            TAG_ContractMetricsService.applyChanges(scope);
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
            Test.stopTest();

            Assert.areEqual(0, dmlUsed, 'A scope without eligible changes must not trigger any DML');
        }
    }

    @IsTest
    static void shouldThrowAndLogWhenSaveFails() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> scope = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000005'
            ];
            delete as system [
                SELECT Id
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000005'
                LIMIT 1
            ];

            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                TAG_ContractMetricsService.applyChanges(scope);
            } catch (TAG_ContractMetricsService.ContractMetricsException e) {
                exceptionThrown = true;
                Assert.isNotNull(e.getMessage(), 'The exception must carry the underlying save error message');
            }
            Test.stopTest();

            Assert.isTrue(exceptionThrown, 'A failed save must surface as a ContractMetricsException');
        }
    }
    @IsTest
    static void shouldProcessBulkScopeWithOneDmlStatement() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            List<Contract__c> contracts = [
                SELECT
                    Id,
                    TAG_Account__c,
                    TAG_StartDate__c,
                    TAG_EndDate__c,
                    TAG_Status__c,
                    TAG_NumberOfHiredCandidates__c,
                    TAG_NumberOfPresentedCandidates__c,
                    TAG_NumberOfMeetings__c
                FROM Contract__c
                WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000006'
            ];
            Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            new TAG_ContractMetricsBatch().execute(null, contracts);
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
            Test.stopTest();

            Assert.areEqual(1, dmlUsed, 'The scope must use exactly one update operation');
            Assert.areEqual(
                251,
                [
                    SELECT COUNT()
                    FROM Contract__c
                    WHERE TAG_account__r.INT_OrganizationNumber__c = '9000000006' AND TAG_NumberOfMeetings__c = 0
                ],
                'Every contract in the bulk scope must be processed'
            );
        }
    }

    private static Account buildAccount(String organizationNumber) {
        return new Account(
            Name = 'Contract metrics test',
            INT_OrganizationNumber__c = organizationNumber,
            INT_MunicipalityNumber__c = '3301'
        );
    }

    private static Contract__c buildContract(
        Id accountId,
        Date startDate,
        Date endDate,
        String status,
        Integer initialValue
    ) {
        return new Contract__c(
            TAG_Account__c = accountId,
            TAG_Category__c = 'Markedssamarbeid',
            TAG_Contact__c = contactId,
            TAG_InternalContact__c = UserInfo.getUserId(),
            TAG_Description__c = 'Contract metrics test',
            TAG_ExternalURL__c = 'https://example.com',
            TAG_StartDate__c = startDate,
            TAG_EndDate__c = endDate,
            TAG_Status__c = status,
            TAG_NumberOfHiredCandidates__c = initialValue,
            TAG_NumberOfPresentedCandidates__c = initialValue,
            TAG_NumberOfMeetings__c = initialValue,
            RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
                .get('EmployerAgreement')
                .getRecordTypeId()
        );
    }

    private static CandidateOutcome__c buildOutcome(
        Id accountId,
        String result,
        Date registeredDate,
        Integer hour,
        Integer minute
    ) {
        CandidateOutcome__c outcome = new CandidateOutcome__c(
            Result__c = result,
            TimeRegistered__c = Datetime.newInstance(registeredDate, Time.newInstance(hour, minute, 0, 0))
        );
        // PRESENTERT stores the related account in Account2__c, all other results use Account__c.
        if (result == 'PRESENTERT') {
            outcome.Account2__c = accountId;
        } else {
            outcome.Account__c = accountId;
        }
        return outcome;
    }

    private static Event buildMeeting(Id accountId, Date activityDate, String service) {
        return new Event(
            Subject = 'Contract metrics test meeting',
            ActivityDate = activityDate,
            IsAllDayEvent = true,
            DurationInMinutes = 1440,
            WhatId = accountId,
            RelatedToAccount__c = accountId,
            TAG_ActivityType__c = 'Rekruttere og inkludere',
            TAG_service__c = service,
            TAG_NoPersonInformation__c = true
        );
    }
}
