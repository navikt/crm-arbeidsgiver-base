@IsTest
private class TAG_EmployerInquiryConversionTest {
    private static final String TEST_USER_LAST_NAME = 'InquiryConversionTestUser';

    @TestSetup
    static void makeData() {
        TAG_TestDataFactory.createUserWithPermset(
            TEST_USER_LAST_NAME,
            new List<String>{
                'Arbeidsgiver_base',
                'Arbeidsgiver_NavTask',
                'Arbeidsgiver_opportunity',
                'Arbeidsgiver_Henvendelser',
                'Admin_Base'
            }
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            NavUnit__c navUnit = new NavUnit__c(Name = 'NAV Test Unit', INT_UnitNumber__c = '9999');
            insert navUnit;

            List<Account> arbeidsgiverUserAccounts = new List<Account>();
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount0',
                    INT_OrganizationNumber__c = '9000000001',
                    INT_MunicipalityNumber__c = '3301',
                    NumberOfWorkfare__c = 5
                )
            );
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    INT_MunicipalityNumber__c = '3301',
                    TAG_Partner_Status__c = null,
                    NumberOfWorkfare__c = 0
                )
            );
            insert arbeidsgiverUserAccounts;
            Id navTaskRecordTypeId = Schema.SObjectType.NavTask__c.getRecordTypeInfosByDeveloperName()
                .get('Employer')
                .getRecordTypeId();

            List<NavTask__c> navTasks = new List<NavTask__c>();
            navTasks.add(
                new NavTask__c(
                    Name = 'Test Nav Task 1',
                    RecordTypeId = navTaskRecordTypeId,
                    CRM_Status__c = 'Ny',
                    CRM_Account__c = arbeidsgiverUserAccounts[0].Id,
                    CRM_NavUnit__c = navUnit.Id,
                    CRM_Theme__c = 'Forebygge sykefravær og redusere frafall',
                    CRM_SubTheme__c = 'Redusere sykefravær',
                    CRM_DueDate__c = Date.today().addDays(2),
                    CRM_ConversationNote__c = 'Testnotat',
                    CRM_AdditionalInformation__c = 'Ekstra info'
                )
            );
            navTasks.add(
                new NavTask__c(
                    Name = 'Test Nav Task 2',
                    RecordTypeId = navTaskRecordTypeId,
                    CRM_Status__c = 'Ny',
                    CRM_Account__c = arbeidsgiverUserAccounts[0].Id,
                    CRM_NavUnit__c = navUnit.Id,
                    CRM_Theme__c = 'Rekruttere og inkludere',
                    CRM_SubTheme__c = 'Rekrutteringsoppdrag',
                    CRM_DueDate__c = Date.today().addDays(2),
                    CRM_ConversationNote__c = 'Testnotat',
                    CRM_AdditionalInformation__c = 'Ekstra info'
                )
            );
            navTasks.add(
                new NavTask__c(
                    Name = 'Test Nav Task 3',
                    RecordTypeId = navTaskRecordTypeId,
                    CRM_Status__c = 'Ny',
                    CRM_Account__c = arbeidsgiverUserAccounts[0].Id,
                    CRM_NavUnit__c = navUnit.Id,
                    CRM_Theme__c = 'Rekruttere og inkludere',
                    CRM_SubTheme__c = null,
                    CRM_DueDate__c = Date.today().addDays(2),
                    CRM_ConversationNote__c = 'Testnotat',
                    CRM_AdditionalInformation__c = 'Ekstra info'
                )
            );
            insert navTasks;

            Id inclusionRtId = Schema.SObjectType.CustomOpportunity__c.getRecordTypeInfosByDeveloperName()
                .get('Inclusion')
                .getRecordTypeId();

            List<CustomOpportunity__c> opps = new List<CustomOpportunity__c>();
            opps.add(
                new CustomOpportunity__c(
                    Account__c = arbeidsgiverUserAccounts[0].Id,
                    TAG_NavUnit__c = navUnit.Id,
                    Source__c = 'Arbeidsplassen',
                    InquiryCategory__c = 'Skal ansette',
                    InclusionStage__c = 'Ny henvendelse',
                    RecordTypeId = inclusionRtId,
                    INT_MunicipalityNumber__c = '0101',
                    Notes__c = 'Testmelding',
                    TAG_DueDateTime__c = DateTime.now().addDays(2)
                )
            );
            insert opps;
        }
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE LastName = :TEST_USER_LAST_NAME LIMIT 1];
    }

    private static TAG_EmployerInquiryConversion.ConversionRequest createRequest(
        Boolean navTasks,
        Boolean opportunities
    ) {
        TAG_EmployerInquiryConversion.ConversionRequest req = new TAG_EmployerInquiryConversion.ConversionRequest();
        req.convertNavTasks = navTasks;
        req.convertCustomOpportunities = opportunities;
        req.createdOnOrAfter = Datetime.now().addDays(-1);
        return req;
    }

    @IsTest
    static void convertNavTasks() {
        NavTask__c navTask = [
            SELECT Id, Name, CRM_Account__c, CRM_NavUnit__c, CRM_DueDate__c
            FROM NavTask__c
            WHERE Name = 'Test Nav Task 2'
            LIMIT 1
        ];
        User testUser = getTestUser();

        Test.startTest();
        System.runAs(testUser) {
            List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
                new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(true, false) }
            );
            System.assertEquals(3, results[0].successCount);
            System.assertEquals(0, results[0].errorCount);
        }
        Test.stopTest();

        EmployerInquiry__c inquiry = [
            SELECT
                Name,
                TAG_Account__c,
                TAG_NavUnit__c,
                TAG_Message__c,
                TAG_DueDate__c,
                TAG_Status__c,
                TAG_Source__c,
                TAG_Theme__c,
                TAG_SubTheme__c,
                TAG_Converted_NAV_Task__c
            FROM EmployerInquiry__c
            WHERE TAG_Converted_NAV_Task__c = :navTask.Id
            LIMIT 1
        ];
        System.assertEquals(navTask.Name, inquiry.Name);
        System.assertEquals(navTask.CRM_Account__c, inquiry.TAG_Account__c);
        System.assertEquals(navTask.CRM_NavUnit__c, inquiry.TAG_NavUnit__c);
        System.assertEquals(navTask.CRM_DueDate__c, inquiry.TAG_DueDate__c);
        System.assertEquals(navTask.Id, inquiry.TAG_Converted_NAV_Task__c);
        System.assertEquals('Ny henvendelse', inquiry.TAG_Status__c);
        System.assertEquals('Kontaktsenteret', inquiry.TAG_Source__c);
        System.assertEquals('Rekruttere og inkludere', inquiry.TAG_Theme__c);
        System.assertEquals('Rekruttering uten virkemidler', inquiry.TAG_SubTheme__c);
        System.assert(inquiry.TAG_Message__c.contains('Testnotat'));
        System.assert(inquiry.TAG_Message__c.contains('Ekstra info'));
    }

    @IsTest
    static void convertOpportunities() {
        CustomOpportunity__c opp = [
            SELECT Id, Account__c, Contact__c, TAG_NavUnit__c
            FROM CustomOpportunity__c
            LIMIT 1
        ];

        User testUser = getTestUser();

        Test.startTest();
        System.runAs(testUser) {
            List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
                new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(false, true) }
            );
            System.assertEquals(1, results[0].successCount);
            System.assertEquals(0, results[0].errorCount);
        }
        Test.stopTest();

        EmployerInquiry__c inquiry = [
            SELECT
                TAG_Account__c,
                TAG_Contact__c,
                TAG_Status__c,
                TAG_Message__c,
                TAG_NavUnit__c,
                TAG_Source__c,
                TAG_Theme__c,
                TAG_SubTheme__c,
                TAG_DueDate__c,
                TAG_DueDateTime__c,
                TAG_Converted_Custom_Opportunity__c
            FROM EmployerInquiry__c
            WHERE TAG_Converted_Custom_Opportunity__c = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(opp.Account__c, inquiry.TAG_Account__c);
        System.assertEquals(opp.Contact__c, inquiry.TAG_Contact__c);
        System.assertEquals(opp.TAG_NavUnit__c, inquiry.TAG_NavUnit__c);
        System.assertEquals(opp.Id, inquiry.TAG_Converted_Custom_Opportunity__c);
        System.assertEquals('Ny henvendelse', inquiry.TAG_Status__c);
        System.assertEquals('Arbeidsplassen.no', inquiry.TAG_Source__c);
        System.assertEquals('Rekruttere og inkludere', inquiry.TAG_Theme__c);
        System.assertEquals(null, inquiry.TAG_SubTheme__c);
        System.assertEquals('Testmelding', inquiry.TAG_Message__c);
        System.assertNotEquals(null, inquiry.TAG_DueDate__c);
        System.assertNotEquals(null, inquiry.TAG_DueDateTime__c);
    }

    @IsTest
    static void convertBoth() {
        User testUser = getTestUser();

        Test.startTest();
        System.runAs(testUser) {
            List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
                new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(true, true) }
            );
            System.assertEquals(4, results[0].successCount);
            System.assertEquals(0, results[0].errorCount);
            System.assert(results[0].errorMessages.isEmpty());
        }
        Test.stopTest();
    }
}
