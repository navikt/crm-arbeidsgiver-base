@isTest
private class AccountSummaryControllerTest {
    private static final String SUMMARY_USER = 'SUMMARY ARBEIDSGIVER USER';

    // Access comes only from permission sets, so results do not depend on the running admin's access.
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            SUMMARY_USER,
            new List<String>{
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'ArbeidsgiverStillinger',
                'Arbeidsgiver_Henvendelser',
                'Arbeidsgiver_Workfare'
            }
        );
        Id summaryUserId = getUser().Id;

        User navUser = TAG_TestDataFactory.createStandardUser('SUMMARY NAV USER');

        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
            Account account = accounts[0];
            account.OwnerId = summaryUserId;
            update account;

            List<CustomOpportunity__c> opportunities = TAG_TestDataFactory.getCustomOpportunities(4, false);
            for (Integer i = 0; i < opportunities.size(); i++) {
                CustomOpportunity__c opportunity = opportunities[i];
                opportunity.Account__c = account.Id;
                opportunity.InquiryCategory__c = 'Skal ansette';
                if (i == 3) {
                    opportunity.InclusionStage__c = 'Avsluttet';
                    opportunity.Result__c = 'Arbeidstrening';
                    opportunity.TAG_Resolved_Date_Time__c = Datetime.now().addDays(-1);
                }
            }
            insert opportunities;

            insert new List<EmployerInquiry__c>{
                new EmployerInquiry__c(
                    TAG_Account__c = account.Id,
                    TAG_Status__c = 'Ny henvendelse',
                    TAG_Source__c = 'Kontaktsenteret'
                ),
                new EmployerInquiry__c(
                    TAG_Account__c = account.Id,
                    TAG_Status__c = 'Følges opp',
                    TAG_Source__c = 'Kontaktsenteret'
                ),
                new EmployerInquiry__c(
                    TAG_Account__c = account.Id,
                    TAG_Status__c = 'Fullført',
                    TAG_ClosedReason__c = 'Utforsker samarbeid videre / oppfølging planlagt',
                    TAG_ResolvedDate__c = Datetime.now().addDays(-2),
                    TAG_Source__c = 'Kontaktsenteret'
                )
            };

            Contact employerContact = new Contact(FirstName = 'Test', LastName = 'Kontakt', AccountId = account.Id);
            insert employerContact;
            insert new Contract__c(
                TAG_Account__c = account.Id,
                TAG_Category__c = 'Markedssamarbeid',
                TAG_StartDate__c = Date.today(),
                TAG_EndDate__c = Date.today().addDays(30),
                TAG_Status__c = 'Godkjent',
                TAG_Description__c = 'test',
                TAG_Contact__c = employerContact.Id,
                TAG_InternalContact__c = UserInfo.getUserId(),
                TAG_ExternalURL__c = 'www.example.com',
                OwnerId = summaryUserId,
                RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
                    .get('EmployerAgreement')
                    .getRecordTypeId()
            );

            insert new List<JobPosting__c>{
                new JobPosting__c(
                    Account__c = account.Id,
                    Published__c = Date.today(),
                    Expires__c = Date.today().addDays(3),
                    Status__c = 'ACTIVE',
                    Source__c = 'DIR',
                    Title__c = 'Butikkmedarbeider',
                    OwnerId = summaryUserId
                ),
                new JobPosting__c(
                    Account__c = account.Id,
                    Published__c = Date.today(),
                    Expires__c = Date.today().addDays(30),
                    Status__c = 'ACTIVE',
                    Source__c = 'FINN',
                    Title__c = 'Offentlig utlyst',
                    OwnerId = summaryUserId
                )
            };

            insert new Workfare__c(
                Account__c = account.Id,
                Name = '1234',
                StartDate__c = Date.today().addDays(-10),
                EndDate__c = Date.today().addDays(30),
                Status__c = 'GJENNOMFØRES',
                Type__c = 'MENTOR',
                NavIdent__c = 'C4567'
            );

            insert new List<Task>{
                new Task(
                    Subject = 'Ring butikksjef',
                    RelatedToAccount__c = account.Id,
                    ActivityDate = Date.today().addDays(2),
                    Status = 'Not Started',
                    OwnerId = summaryUserId
                ),
                new Task(
                    Subject = 'Telefonsamtale',
                    RelatedToAccount__c = account.Id,
                    ActivityDate = Date.today(),
                    Type = 'Call',
                    Status = 'Completed',
                    OwnerId = summaryUserId
                )
            };
            insert new Event(
                Subject = 'Møte med arbeidsgiver',
                RelatedToAccount__c = account.Id,
                StartDateTime = Datetime.now().addDays(-3),
                EndDateTime = Datetime.now().addDays(-3).addHours(1),
                OwnerId = summaryUserId
            );

            insert new AccountTeamMember(AccountId = account.Id, UserId = navUser.Id, TAG_Active__c = true);
        }
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE LastName = :SUMMARY_USER LIMIT 1];
    }

    private static Account getAccount() {
        return [SELECT Id, Name FROM Account LIMIT 1];
    }

    private static AccountSummaryService.OngoingRow findRow(AccountSummaryService.Summary summary, String key) {
        for (AccountSummaryService.OngoingRow row : summary.ongoing) {
            if (row.key == key) {
                return row;
            }
        }
        return null;
    }

    private static String joinText(AccountSummaryService.Summary summary) {
        String text = '';
        for (AccountSummaryService.TextPart part : summary.summaryParts) {
            text += part.text;
        }
        return text;
    }

    @isTest
    static void shouldBuildSummaryForAccount() {
        Account account = getAccount();

        AccountSummaryService.Summary summary;
        Test.startTest();
        System.runAs(getUser()) {
            summary = AccountSummaryController.getSummary(account.Id, 6);
        }
        Test.stopTest();

        Assert.isTrue(summary.hasAccount, 'Account should be resolved');
        Assert.isFalse(summary.isInquiryContext, 'Account page is not inquiry context');
        Assert.isTrue(summary.hasOngoingActivity, 'Account has ongoing activity');
        Assert.areEqual(AccountSummaryService.COORDINATION_NOTICE, summary.coordinationNotice, 'Notice expected');
        Assert.areEqual(7, summary.ongoing.size(), 'All ongoing rows should be returned');

        Assert.areEqual(3, findRow(summary, 'mulighet').count, 'Three open opportunities');
        Assert.areEqual('Skal ansette ×3', findRow(summary, 'mulighet').details, 'Opportunities grouped by category');
        Assert.areEqual(2, findRow(summary, 'henvendelse').count, 'Two open inquiries');
        Assert.areEqual(1, findRow(summary, 'avtale').count, 'One active agreement');
        Assert.isTrue(findRow(summary, 'avtale').details.contains('gyldig til'), 'Agreement shows end date');
        Assert.areEqual(1, findRow(summary, 'stilling').count, 'Only direct-reported postings are counted');
        Assert.isNotNull(findRow(summary, 'stilling').pill, 'Deadline within a week is highlighted');
        Assert.areEqual(1, findRow(summary, 'tiltak').count, 'One active workfare');
        Assert.areEqual(1, findRow(summary, 'planlagt').count, 'One planned task');
        Assert.isTrue(findRow(summary, 'planlagt').details.contains('Ring butikksjef'), 'Next planned shown');

        Assert.isNotNull(summary.navContact, 'Nav contact should be returned');
        Assert.areEqual(0, summary.navContact.additionalCount, 'Only one Nav contact');

        Assert.areEqual(6, summary.history.size(), 'Six months of history');
        Assert.areEqual(4, summary.historyTotal, 'Closed opportunity, closed inquiry, call and meeting');
        String text = joinText(summary);
        Assert.isTrue(text.startsWith('Bedriften har 3 åpne muligheter'), 'Unexpected text: ' + text);
        Assert.isTrue(text.contains('1 planlagt oppgave'), 'Numbers instead of words: ' + text);
        Assert.isTrue(text.contains('Siste kontakt var telefon'), 'Last contact expected: ' + text);
    }

    @isTest
    static void shouldReturnTwelveMonthsWhenRequested() {
        Account account = getAccount();
        AccountSummaryService.Summary twelveMonths;
        AccountSummaryService.Summary invalidPeriod;
        System.runAs(getUser()) {
            twelveMonths = AccountSummaryController.getSummary(account.Id, 12);
            invalidPeriod = AccountSummaryController.getSummary(account.Id, 99);
        }
        Assert.areEqual(12, twelveMonths.history.size(), 'Twelve months of history');
        Assert.areEqual(12, twelveMonths.months, 'Period should be 12');
        Assert.areEqual(6, invalidPeriod.months, 'Invalid period defaults to 6');
    }

    @isTest
    static void shouldExcludeCurrentInquiryInInquiryContext() {
        Account account = getAccount();
        EmployerInquiry__c inquiry = [SELECT Id FROM EmployerInquiry__c WHERE TAG_Status__c = 'Følges opp' LIMIT 1];

        AccountSummaryService.Summary summary;
        List<BadgeService.RecordWrapper> records;
        System.runAs(getUser()) {
            summary = AccountSummaryController.getSummary(inquiry.Id, 6);
            records = AccountSummaryController.getRecords(inquiry.Id, 'henvendelse');
        }

        Assert.isTrue(summary.isInquiryContext, 'Inquiry context expected');
        Assert.areEqual(account.Id, summary.accountId, 'Account resolved from inquiry');
        Assert.areEqual(1, findRow(summary, 'henvendelse').count, 'Current inquiry is excluded');
        String text = joinText(summary);
        Assert.isTrue(text.startsWith(account.Name + ' har'), 'Account name used in inquiry context: ' + text);
        Assert.isTrue(text.contains('Merk:'), 'Warning about other open inquiries expected: ' + text);
        Assert.areEqual(1, records.size(), 'Current inquiry is excluded from list');
    }

    @isTest
    static void shouldReturnRecordsForEachRow() {
        Account account = getAccount();
        Map<String, List<BadgeService.RecordWrapper>> recordsByKey = new Map<String, List<BadgeService.RecordWrapper>>();
        System.runAs(getUser()) {
            for (
                String key : new List<String>{ 'mulighet', 'stilling', 'avtale', 'tiltak', 'planlagt', 'navkontakt' }
            ) {
                recordsByKey.put(key, AccountSummaryController.getRecords(account.Id, key));
            }
        }
        Assert.areEqual(3, recordsByKey.get('mulighet').size(), 'Opportunities');
        Assert.areEqual(1, recordsByKey.get('stilling').size(), 'Job postings');
        Assert.areEqual(1, recordsByKey.get('avtale').size(), 'Agreements');
        Assert.areEqual(1, recordsByKey.get('tiltak').size(), 'Workfare');

        List<BadgeService.RecordWrapper> planned = recordsByKey.get('planlagt');
        Assert.areEqual(1, planned.size(), 'Planned activities');
        Assert.areEqual('Ring butikksjef', planned[0].name, 'Planned task name');
        Assert.areEqual(4, planned[0].fields.size(), 'Planned fields');

        Assert.areEqual(1, recordsByKey.get('navkontakt').size(), 'Nav contacts');
    }

    @isTest
    static void shouldThrowForUnknownKey() {
        Account account = getAccount();
        System.runAs(getUser()) {
            try {
                AccountSummaryController.getRecords(account.Id, 'unknown');
                Assert.fail('Exception expected');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Message expected');
            }
        }
    }

    @isTest
    static void shouldHandleMissingOrUnsupportedRecord() {
        User summaryUser = getUser();
        System.runAs(summaryUser) {
            AccountSummaryService.Summary summary = AccountSummaryController.getSummary(null, 6);
            Assert.isFalse(summary.hasAccount, 'No account for null id');

            summary = AccountSummaryController.getSummary(summaryUser.Id, 6);
            Assert.isFalse(summary.hasAccount, 'Unsupported object type');

            Assert.isTrue(AccountSummaryController.getRecords(null, 'mulighet').isEmpty(), 'Empty list for null id');
        }
    }

    @isTest
    static void shouldFormatHelpers() {
        Assert.areEqual('05.11', AccountSummaryService.formatDate(Date.newInstance(2026, 11, 5), false), 'dd.mm');
        Assert.areEqual(
            '05.11.2026',
            AccountSummaryService.formatDate(Date.newInstance(2026, 11, 5), true),
            'dd.mm.yyyy'
        );
        Assert.areEqual('KN', AccountSummaryService.initials('Kari Nordmann'), 'Initials');
        Assert.areEqual('', AccountSummaryService.initials(null), 'Blank initials');
        Assert.areEqual(
            'A ×2 · B ×1 · C ×1 · …',
            AccountSummaryService.groupLabels(new List<String>{ 'A', 'B', 'A', 'C', 'D' }),
            'Grouped labels'
        );
        Assert.areEqual('A', AccountSummaryService.groupLabels(new List<String>{ 'A' }), 'Single label');
    }
}
