@IsTest(SeeAllData=false)
private class TAG_NavUnitOverviewControllerTest {
    private static final String INQUIRY_CLOSED_REASON = 'Fikk ikke tak i arbeidsgiveren';

    @TestSetup
    static void makeData() {
        Id employerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Employer')
            .getRecordTypeId();

        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{ 'Arbeidsgiver_base', 'Arbeidsgiver_Henvendelser', 'Arbeidsgiver_Kandidatutfall' }
        );
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        TAG_TestDataFactory.createUserWithPermset('OTHER USER', new List<String>{});

        System.runAs(arbeidsgiverUser) {
            List<NavUnit__c> navUnits = new List<NavUnit__c>{
                new NavUnit__c(Name = 'NAV test 9001', INT_UnitNumber__c = '9001'),
                new NavUnit__c(Name = 'NAV test 9002', INT_UnitNumber__c = '9002'),
                new NavUnit__c(Name = 'NAV test 9003', INT_UnitNumber__c = '9003')
            };
            Database.insert(navUnits, AccessLevel.SYSTEM_MODE);

            List<Account> employers = new List<Account>{
                new Account(
                    Name = 'Testarbeidsgiver 1',
                    INT_OrganizationNumber__c = '99999901',
                    RecordTypeId = employerRecordTypeId,
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_LastEventDate__c = Date.today()
                ),
                new Account(
                    Name = 'Testarbeidsgiver 2',
                    INT_OrganizationNumber__c = '99999902',
                    RecordTypeId = employerRecordTypeId,
                    TAG_NavUnit__c = navUnits[1].Id,
                    TAG_LastEventDate__c = Date.today()
                ),
                new Account(
                    Name = 'Testarbeidsgiver 3',
                    INT_OrganizationNumber__c = '99999903',
                    RecordTypeId = employerRecordTypeId,
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_LastEventDate__c = Date.today().addDays(-91)
                ),
                new Account(
                    Name = 'Testarbeidsgiver 4',
                    INT_OrganizationNumber__c = '99999904',
                    RecordTypeId = employerRecordTypeId,
                    TAG_NavUnit__c = navUnits[1].Id,
                    TAG_LastEventDate__c = Date.today().addDays(-90)
                )
            };
            Database.insert(employers, AccessLevel.SYSTEM_MODE);

            List<EmployerInquiry__c> employerInquiries = new List<EmployerInquiry__c>{
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_ClosedAfterDueDate__c = false,
                    TAG_IsConversationNote__c = false,
                    TAG_RecievedDateTime__c = Datetime.now(),
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = INQUIRY_CLOSED_REASON
                ),
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_ClosedAfterDueDate__c = true,
                    TAG_IsConversationNote__c = false,
                    TAG_RecievedDateTime__c = Datetime.now(),
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = INQUIRY_CLOSED_REASON
                ),
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_ClosedAfterDueDate__c = false,
                    TAG_IsConversationNote__c = true,
                    TAG_RecievedDateTime__c = Datetime.now(),
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = INQUIRY_CLOSED_REASON
                ),
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_ClosedAfterDueDate__c = false,
                    TAG_IsConversationNote__c = false,
                    TAG_RecievedDateTime__c = Datetime.now().addDays(-91),
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = INQUIRY_CLOSED_REASON
                ),
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[0].Id,
                    TAG_ClosedAfterDueDate__c = false,
                    TAG_IsConversationNote__c = false,
                    TAG_RecievedDateTime__c = Datetime.now(),
                    TAG_Status__c = 'Ny henvendelse'
                ),
                new EmployerInquiry__c(
                    TAG_NavUnit__c = navUnits[1].Id,
                    TAG_ClosedAfterDueDate__c = false,
                    TAG_IsConversationNote__c = false,
                    TAG_RecievedDateTime__c = Datetime.now(),
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = INQUIRY_CLOSED_REASON
                )
            };
            Database.insert(employerInquiries, AccessLevel.SYSTEM_MODE);
            List<CandidateOutcome__c> candidateOutcomes = new List<CandidateOutcome__c>{
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[0].Id,
                    Result__c = 'PRESENTERT',
                    TimeRegistered__c = Datetime.now()
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[0].Id,
                    Result__c = 'PRESENTERT',
                    TimeRegistered__c = Datetime.now()
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[0].Id,
                    Result__c = 'FATT_JOBBEN',
                    TimeRegistered__c = Datetime.now()
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[0].Id,
                    Result__c = 'AVBRUTT',
                    TimeRegistered__c = Datetime.now()
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[0].Id,
                    Result__c = 'PRESENTERT',
                    TimeRegistered__c = Datetime.now().addDays(-91)
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[1].Id,
                    Result__c = 'PRESENTERT',
                    TimeRegistered__c = Datetime.now()
                ),
                new CandidateOutcome__c(
                    NavUnit__c = navUnits[1].Id,
                    Result__c = 'FATT_JOBBEN',
                    TimeRegistered__c = Datetime.now()
                )
            };
            Database.insert(candidateOutcomes, AccessLevel.SYSTEM_MODE);
        }
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenCurrentAndExcludedData_whenGetOverview_thenOnlyRelevantMetricsAreReturned() {
        TAG_NavUnitOverviewController.NavUnitOverviewData result;
        Id navUnitId = [SELECT Id FROM NavUnit__c WHERE INT_UnitNumber__c = '9001' LIMIT 1].Id;
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            result = TAG_NavUnitOverviewController.getOverview(navUnitId);
            Test.stopTest();
        }
        Assert.areEqual(2, result.inquiriesClosedCount, 'Incorrect number of closed inquiries');
        Assert.areEqual(
            1,
            result.inquiriesClosedWithinDeadlineCount,
            'Incorrect number of inquiries closed within deadline'
        );
        Assert.areEqual(2, result.candidatesPresentedCount, 'Incorrect number of candidates presented');
        Assert.areEqual(1, result.candidatesPlacedCount, 'Incorrect number of candidates placed');
        Assert.areEqual(1, result.employersWithActivityCount, 'Incorrect number of employers with activity');
        Assert.areEqual(0, result.daysSinceLastActivity, 'Incorrect number of days since last activity');
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenNavUnitWithoutData_whenGetOverview_thenZeroMetricsAndNullLastActivityAreReturned() {
        TAG_NavUnitOverviewController.NavUnitOverviewData result;
        Id navUnitId = [SELECT Id FROM NavUnit__c WHERE INT_UnitNumber__c = '9003' LIMIT 1].Id;
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            result = TAG_NavUnitOverviewController.getOverview(navUnitId);
            Test.stopTest();
        }
        Assert.areEqual(0, result.inquiriesClosedCount, 'Incorrect number of closed inquiries');
        Assert.areEqual(
            0,
            result.inquiriesClosedWithinDeadlineCount,
            'Incorrect number of inquiries closed within deadline'
        );
        Assert.areEqual(0, result.candidatesPresentedCount, 'Incorrect number of candidates presented');
        Assert.areEqual(0, result.candidatesPlacedCount, 'Incorrect number of candidates placed');
        Assert.areEqual(0, result.employersWithActivityCount, 'Incorrect number of employers with activity');
        Assert.isNull(result.daysSinceLastActivity, 'Incorrect number of days since last activity');
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenNullNavUnitId_whenGetOverview_thenRequiredParameterExceptionIsThrown() {
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        Boolean didThrow = false;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            try {
                TAG_NavUnitOverviewController.getOverview(null);
            } catch (AuraHandledException e) {
                didThrow = true;
            }
            Test.stopTest();
        }
        Assert.isTrue(didThrow, 'Metoden skal ikke godta en manglende NAV-enhet');
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenUserWithoutAccess_whenGetOverview_thenAuraHandledExceptionIsThrown() {
        TAG_NavUnitOverviewController.NavUnitOverviewData result;
        User otherUser = [SELECT id FROM User WHERE LastName = 'OTHER USER' LIMIT 1];
        Id navUnitId = [SELECT Id FROM NavUnit__c WHERE INT_UnitNumber__c = '9001' LIMIT 1].Id;
        Boolean didThrow = false;
        System.runAs(otherUser) {
            Test.startTest();
            try {
                result = TAG_NavUnitOverviewController.getOverview(navUnitId);
                Assert.fail('Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                didThrow = true;
            }
            Test.stopTest();
        }
        Assert.isTrue(didThrow, 'Expected AuraHandledException was not thrown');
        Assert.isNull(result, 'Result should be null when user does not have access');
    }
}
