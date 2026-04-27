@IsTest
private class TAG_EmployerInquiryConversionTest {
    @TestSetup
    static void makeData() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        Account acc = accounts[0];

        NavUnit__c navUnit = new NavUnit__c(Name = 'NAV Test Unit', INT_UnitNumber__c = '9999');
        insert navUnit;

        NavTask__c navTask = new NavTask__c(
            CRM_Account__c = acc.Id,
            CRM_NavUnit__c = navUnit.Id,
            CRM_Theme__c = 'Rekruttere og inkludere',
            CRM_SubTheme__c = 'Rekrutteringsoppdrag',
            CRM_DueDate__c = Date.today().addDays(7),
            CRM_ConversationNote__c = 'Testnotat',
            CRM_AdditionalInformation__c = 'Ekstra info'
        );
        insert navTask;
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
        NavTask__c navTask = [SELECT Id, Name, CRM_Account__c, CRM_NavUnit__c, CRM_DueDate__c FROM NavTask__c LIMIT 1];

        Test.startTest();
        List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
            new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(true, false) }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].successCount);
        System.assertEquals(0, results[0].errorCount);

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
        Account acc = [SELECT Id FROM Account LIMIT 1];
        NavUnit__c navUnit = [SELECT Id FROM NavUnit__c LIMIT 1];
        List<Contact> contacts = TAG_TestDataFactory.createContacts(new List<Account>{ acc }, 1);

        Id inclusionRtId = Schema.SObjectType.CustomOpportunity__c.getRecordTypeInfosByDeveloperName()
            .get('Inclusion')
            .getRecordTypeId();

        CustomOpportunity__c opp = new CustomOpportunity__c(
            Account__c = acc.Id,
            Contact__c = contacts[0].Id,
            TAG_NavUnit__c = navUnit.Id,
            Source__c = 'Kontaktskjema',
            InquiryCategory__c = 'Forebygge sykefravær',
            InclusionStage__c = 'Ny henvendelse',
            RecordTypeId = inclusionRtId,
            Notes__c = 'Testmelding',
            INT_MunicipalityNumber__c = '0101',
            TAG_DueDateTime__c = Datetime.now().addDays(5)
        );
        insert opp;

        Test.startTest();
        List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
            new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(false, true) }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].successCount);
        System.assertEquals(0, results[0].errorCount);

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
        System.assertEquals(acc.Id, inquiry.TAG_Account__c);
        System.assertEquals(contacts[0].Id, inquiry.TAG_Contact__c);
        System.assertEquals(navUnit.Id, inquiry.TAG_NavUnit__c);
        System.assertEquals(opp.Id, inquiry.TAG_Converted_Custom_Opportunity__c);
        System.assertEquals('Ny henvendelse', inquiry.TAG_Status__c);
        System.assertEquals('Kontaktskjema', inquiry.TAG_Source__c);
        System.assertEquals('Forebygge og redusere fravær', inquiry.TAG_Theme__c);
        System.assertEquals(null, inquiry.TAG_SubTheme__c);
        System.assertEquals('Testmelding', inquiry.TAG_Message__c);
        System.assertNotEquals(null, inquiry.TAG_DueDate__c);
        System.assertNotEquals(null, inquiry.TAG_DueDateTime__c);
    }

    @IsTest
    static void convertBoth() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        NavUnit__c navUnit = [SELECT Id FROM NavUnit__c LIMIT 1];

        Id inclusionRtId = Schema.SObjectType.CustomOpportunity__c.getRecordTypeInfosByDeveloperName()
            .get('Inclusion')
            .getRecordTypeId();

        insert new CustomOpportunity__c(
            Account__c = acc.Id,
            TAG_NavUnit__c = navUnit.Id,
            Source__c = 'Arbeidsplassen',
            InquiryCategory__c = 'Skal ansette',
            InclusionStage__c = 'Ny henvendelse',
            RecordTypeId = inclusionRtId,
            INT_MunicipalityNumber__c = '0101'
        );

        Test.startTest();
        List<TAG_EmployerInquiryConversion.ConversionResult> results = TAG_EmployerInquiryConversion.convertAllToEmployerInquiries(
            new List<TAG_EmployerInquiryConversion.ConversionRequest>{ createRequest(true, true) }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].successCount);
        System.assertEquals(0, results[0].errorCount);
        System.assert(results[0].errorMessages.isEmpty());
    }
}
