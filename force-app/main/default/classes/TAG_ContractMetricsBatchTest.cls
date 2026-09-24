@IsTest(SeeAllData=false)
private class TAG_ContractMetricsBatchTest {
    private static final Date START_DATE = Date.newInstance(2026, 1, 10);
    private static final Date END_DATE = Date.newInstance(2026, 1, 20);
    private static Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();

    @IsTest
    static void shouldCalculateAllMetricsAndIgnoreExcludedRecords() {
        Account account = createAccount('9000000001');
        Contract__c contractRecord = createContract(account.Id, START_DATE, END_DATE, 'Godkjent', 9);
        insert new List<CandidateOutcome__c>{
            createOutcome(account.Id, 'PRESENTERT', START_DATE, 0, 0),
            createOutcome(account.Id, 'FATT_JOBBEN', END_DATE, 23, 59),
            createOutcome(account.Id, 'IKKE_PRESENTERT', START_DATE.addDays(1), 12, 0),
            createOutcome(account.Id, 'PRESENTERT', END_DATE.addDays(1), 0, 0)
        };
        insert new List<Event>{
            createMeeting(account.Id, START_DATE, 'Jobbmesser og møteplass'),
            createMeeting(account.Id, END_DATE, 'Jobbmesser og møteplass'),
            createMeeting(account.Id, END_DATE, 'IPS Jobbutvikling')
        };

        Test.startTest();
        Database.executeBatch(new TAG_ContractMetricsBatch(), 200);
        Test.stopTest();

        Contract__c actual = getContract(contractRecord.Id);
        Assert.areEqual(1, actual.TAG_NumberOfPresentedCandidates__c, 'Only one presented outcome is in range');
        Assert.areEqual(1, actual.TAG_NumberOfHiredCandidates__c, 'The end-date outcome must be included');
        Assert.areEqual(2, actual.TAG_NumberOfMeetings__c, 'Both boundary meetings must be included');
    }

    @IsTest
    static void shouldSetMetricsToZeroWhenNoMatchesExist() {
        Account account = createAccount('9000000002');
        Contract__c contractRecord = createContract(account.Id, START_DATE, END_DATE, 'AVSLUTTET', 4);

        Test.startTest();
        Database.executeBatch(new TAG_ContractMetricsBatch(), 200);
        Test.stopTest();

        Contract__c actual = getContract(contractRecord.Id);
        Assert.areEqual(0, actual.TAG_NumberOfPresentedCandidates__c, 'Presented count must be reset');
        Assert.areEqual(0, actual.TAG_NumberOfHiredCandidates__c, 'Hired count must be reset');
        Assert.areEqual(0, actual.TAG_NumberOfMeetings__c, 'Meeting count must be reset');
    }

    @IsTest
    static void shouldHandleOverlappingContractsOnSameAccount() {
        Account account = createAccount('9000000003');
        Contract__c firstContract = createContract(account.Id, START_DATE, END_DATE, 'Godkjent', 0);
        Contract__c secondContract = createContract(
            account.Id,
            START_DATE.addDays(5),
            END_DATE.addDays(5),
            'Godkjent',
            0
        );
        insert new List<CandidateOutcome__c>{
            createOutcome(account.Id, 'PRESENTERT', START_DATE.addDays(2), 12, 0),
            createOutcome(account.Id, 'PRESENTERT', START_DATE.addDays(7), 12, 0),
            createOutcome(account.Id, 'FATT_JOBBEN', END_DATE.addDays(2), 12, 0)
        };

        Test.startTest();
        Database.executeBatch(new TAG_ContractMetricsBatch(), 200);
        Test.stopTest();

        Map<Id, Contract__c> contractsById = new Map<Id, Contract__c>(
            [
                SELECT TAG_NumberOfHiredCandidates__c, TAG_NumberOfPresentedCandidates__c
                FROM Contract__c
                WHERE Id IN :new Set<Id>{ firstContract.Id, secondContract.Id }
            ]
        );
        Assert.areEqual(
            2,
            contractsById.get(firstContract.Id).TAG_NumberOfPresentedCandidates__c,
            'First contract must count both presented outcomes'
        );
        Assert.areEqual(
            1,
            contractsById.get(secondContract.Id).TAG_NumberOfPresentedCandidates__c,
            'Second contract must count only its presented outcome'
        );
        Assert.areEqual(
            1,
            contractsById.get(secondContract.Id).TAG_NumberOfHiredCandidates__c,
            'Second contract must count its hired outcome'
        );
    }

    @IsTest
    static void shouldIgnoreContractsWithOtherStatusesAndAvoidUnchangedUpdates() {
        Account account = createAccount('9000000004');
        Contract__c draftContract = createContract(account.Id, START_DATE, END_DATE, 'Utkast', 7);
        Contract__c unchangedContract = createContract(account.Id, START_DATE, END_DATE, 'Godkjent', 0);
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
            WHERE Id IN :new Set<Id>{ draftContract.Id, unchangedContract.Id }
        ];

        Test.startTest();
        List<Contract__c> changes = TAG_ContractMetricsService.calculateChanges(scope);
        Test.stopTest();

        Assert.areEqual(0, changes.size(), 'Draft and already-zero contracts must not be updated');
    }

    @IsTest
    static void shouldProcessBulkScopeWithOneDmlStatement() {
        Account account = createAccount('9000000005');
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer index = 0; index < 251; index++) {
            contracts.add(buildContract(account.Id, START_DATE, END_DATE, 'Godkjent', 3));
        }
        insert contracts;

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        new TAG_ContractMetricsBatch().execute(null, contracts);
        Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        Assert.areEqual(1, dmlUsed, 'The scope must use exactly one update operation');
        Assert.areEqual(
            251,
            [SELECT COUNT() FROM Contract__c WHERE Id IN :contracts AND TAG_NumberOfMeetings__c = 0],
            'Every contract in the bulk scope must be processed'
        );
    }

    @IsTest
    static void shouldStartBatchWhenScheduled() {
        Test.startTest();
        new TAG_ContractMetricsScheduler().execute(null);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Contract__c], 'Scheduling must complete when there is no work');
    }

    @IsTest
    static void shouldThrowAndLogWhenSaveFails() {
        Account account = createAccount('9000000006');
        Contract__c contractRecord = createContract(account.Id, START_DATE, END_DATE, 'Godkjent', 0);
        insert createOutcome(account.Id, 'PRESENTERT', START_DATE, 12, 0);
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
            WHERE Id = :contractRecord.Id
        ];
        delete contractRecord;

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

    @IsTest
    static void shouldReturnWithoutSavingWhenNoChangesExist() {
        Account account = createAccount('9000000007');
        Contract__c contractRecord = createContract(account.Id, START_DATE, END_DATE, 'Utkast', 0);
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
            WHERE Id = :contractRecord.Id
        ];

        Test.startTest();
        Integer dmlBefore = Limits.getDmlStatements();
        TAG_ContractMetricsService.applyChanges(scope);
        Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        Assert.areEqual(0, dmlUsed, 'A scope without eligible changes must not trigger any DML');
    }

    private static Account createAccount(String organizationNumber) {
        Account account = new Account(
            Name = 'Contract metrics test',
            INT_OrganizationNumber__c = organizationNumber,
            INT_MunicipalityNumber__c = '3301'
        );
        insert account;
        Contact contact = new Contact(LastName = 'Contract metrics contact', AccountId = account.Id);
        insert contact;
        contactIdByAccountId.put(account.Id, contact.Id);
        return account;
    }

    private static Contract__c createContract(
        Id accountId,
        Date startDate,
        Date endDate,
        String status,
        Integer initialValue
    ) {
        Contract__c contractRecord = buildContract(accountId, startDate, endDate, status, initialValue);
        insert contractRecord;
        return contractRecord;
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
            TAG_Contact__c = contactIdByAccountId.get(accountId),
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

    private static CandidateOutcome__c createOutcome(
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

    private static Event createMeeting(Id accountId, Date activityDate, String service) {
        return new Event(
            Subject = 'Contract metrics test meeting',
            ActivityDate = activityDate,
            IsAllDayEvent = true,
            DurationInMinutes = 1440,
            WhatId = accountId,
            RelatedToAccount__c = accountId,
            TAG_ActivityType__c = 'Rekruttere og inkludere',
            TAG_service__c = service
        );
    }

    private static Contract__c getContract(Id contractId) {
        return [
            SELECT TAG_NumberOfHiredCandidates__c, TAG_NumberOfPresentedCandidates__c, TAG_NumberOfMeetings__c
            FROM Contract__c
            WHERE Id = :contractId
        ];
    }
}