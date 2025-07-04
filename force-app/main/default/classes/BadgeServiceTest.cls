@isTest
private class BadgeServiceTest {
    @testSetup
    static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{ 'Arbeidsgiver_base', 'Arbeidsgiver_opportunity' }
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

            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                AccountId = arbeidsgiverUserAccounts[0].Id
            );
            insert testContact;

            List<CustomOpportunity__c> arbeidsgiverUserOpportunities = TAG_TestDataFactory.getCustomOpportunities(
                5,
                false
            );
            Integer i = 0;
            for (CustomOpportunity__c opp : arbeidsgiverUserOpportunities) {
                opp.Account__c = arbeidsgiverUserAccounts[0].Id;
                opp.OwnerId = arbeidsgiverUser.id;
                opp.InclusionStage__c = 'Ny henvendelse';
                opp.InquiryCategory__c = 'Skal ansette';
                opp.Contact__c = testContact.Id;
                opp.OwnerId = arbeidsgiverUser.Id;
            }
            insert arbeidsgiverUserOpportunities;
        }

        TAG_TestDataFactory.createUserWithPermset('USER WITHOUT PERMISSIONS', new List<String>{ 'Arbeidsgiver_base' });
        User negativeAccessUser = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        System.runAs(negativeAccessUser) {
            List<Account> negativeAccessUserAccounts = new List<Account>();
            negativeAccessUserAccounts.add(
                new Account(
                    Name = 'TestAccount1',
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
    static void returnListOfBadgesMatchingConfigAndMergeFields() {
        Map<String, String> config1 = new Map<String, String>{
            'labelTemplate' => 'Test Label {0} {1}',
            'urlTemplate' => 'http://example.com/{0}/{1}/',
            'helpText' => 'Help Text',
            'badgeType' => 'Type',
            'badgeKey' => 'Key',
            'icon' => 'Icon'
        };
        Test.startTest();
        BadgeService.Badge badgeMergeFields = BadgeService.createBadgeFromConfig(
            config1,
            new List<Object>{ 'Label1', 'Label2' },
            new List<Object>{ 'URL1', 'URL2' }
        );
        BadgeService.Badge badgeTooManyMergeFields = BadgeService.createBadgeFromConfig(
            config1,
            new List<Object>{ 'Label1', 'Label2', 'Label3' },
            new List<Object>{ 'URL1', 'URL2', 'URL3' }
        );
        BadgeService.Badge badgeTooFewMergeFields = BadgeService.createBadgeFromConfig(
            config1,
            new List<Object>{ 'Label1' },
            new List<Object>{ 'URL1' }
        );
        BadgeService.Badge badgeEmptyMergeFields = BadgeService.createBadgeFromConfig(
            config1,
            new List<Object>(),
            new List<Object>()
        );
        BadgeService.Badge badgeNullMergeFields = BadgeService.createBadgeFromConfig(config1, null, null);

        Test.stopTest();

        System.assertEquals('Help Text', badgeMergeFields.helpText);
        System.assertEquals('Type', badgeMergeFields.badgeType);
        System.assertEquals('Key', badgeMergeFields.badgeKey);
        System.assertEquals('Icon', badgeMergeFields.icon);

        System.assertEquals('Test Label Label1 Label2', badgeMergeFields.label);
        System.assertEquals('http://example.com/URL1/URL2/', badgeMergeFields.url);

        System.assertEquals('Test Label Label1 Label2', badgeTooManyMergeFields.label);
        System.assertEquals('http://example.com/URL1/URL2/', badgeTooManyMergeFields.url);

        System.assertEquals('Test Label Label1 {1}', badgeTooFewMergeFields.label);
        System.assertEquals('http://example.com/URL1/{1}/', badgeTooFewMergeFields.url);

        System.assertEquals('Test Label {0} {1}', badgeNullMergeFields.label);
        System.assertEquals('http://example.com/{0}/{1}/', badgeNullMergeFields.url);
    }

    @isTest
    static void testGetRecordCount() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        Map<String, String> config = new Map<String, String>{
            'columns' => 'Name,TAG_Link__c, Source__c, InclusionStage__c,OWNER.ALIAS,TAG_Age__c,Position_in_Rekrutteringsbistand__c',
            'objectApiName' => 'CustomOpportunity__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'InclusionStage__c != \'Avsluttet\''
        };
        Integer count;
        System.runAs(user) {
            Test.startTest();
            count = BadgeService.getRecordCount(testAccount.Id, config);
            Test.stopTest();
        }

        Assert.isNotNull(count);
        Assert.areEqual(
            [
                SELECT COUNT()
                FROM CustomOpportunity__c
                WHERE InclusionStage__c != 'Avsluttet' AND Account__c = :testAccount.Id
            ],
            count
        );
    }
    @isTest
    static void serviceShouldReturnNullOnQueryException() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount1' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'USER WITHOUT PERMISSIONS' LIMIT 1];
        List<CustomOpportunity__c> opportunities = TAG_TestDataFactory.getCustomOpportunities(1, false);
        opportunities[0].Account__c = testAccount.Id;
        opportunities[0].InquiryCategory__c = 'Skal ansette';
        opportunities[0].InclusionStage__c = 'Ny henvendelse';
        insert opportunities;

        Map<String, String> config = new Map<String, String>{
            'columns' => 'Name,TAG_Link__c, Source__c, InclusionStage__c,OWNER.ALIAS,TAG_Age__c,Position_in_Rekrutteringsbistand__c',
            'objectApiName' => 'CustomOpportunity__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'InclusionStage__c != \'Avsluttet\''
        };
        Integer count;
        List<SObject> returnedRecords;
        System.runAs(user) {
            Test.startTest();
            count = BadgeService.getRecordCount(testAccount.Id, config);
            returnedRecords = BadgeService.getRecords(testAccount.Id, config);
            Test.stopTest();
        }
        Assert.isNull(count);
        Assert.isNull(returnedRecords);
    }

    @isTest
    static void testGetRecords() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];

        Map<String, String> config = new Map<String, String>{
            'columns' => 'Name,TAG_Link__c, Source__c, InclusionStage__c,OWNER.ALIAS,TAG_Age__c,Position_in_Rekrutteringsbistand__c',
            'objectApiName' => 'CustomOpportunity__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'InclusionStage__c != \'Avsluttet\''
        };
        List<SObject> returnedRecords;
        System.runAs(user) {
            Test.startTest();
            returnedRecords = BadgeService.getRecords(testAccount.Id, config);
            Test.stopTest();
        }
        List<CustomOpportunity__c> opps = [
            SELECT
                Name,
                TAG_Link__c,
                Source__c,
                InclusionStage__c,
                OWNER.ALIAS,
                TAG_Age__c,
                Position_in_Rekrutteringsbistand__c
            FROM CustomOpportunity__c
            WHERE InclusionStage__c != 'Avsluttet' AND Account__c = :testAccount.Id
        ];
        Assert.isNotNull(returnedRecords);
        Assert.areEqual(opps.size(), returnedRecords.size());
    }

    @isTest
    static void convertSObjectReordsToRecordWrapperObjects() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        List<CustomOpportunity__c> records = [
            SELECT Id, InclusionStage__c, InquiryCategory__c, createddate, Account__r.Name, Owner.Alias
            FROM CustomOpportunity__c
            WHERE
                InquiryCategory__c = 'Skal ansette'
                AND InclusionStage__c = 'Ny henvendelse'
                AND Account__c = :testAccount.Id
        ];

        Map<String, String> config = new Map<String, String>{
            'columns' => 'InquiryCategory__c, InclusionStage__c,Account__r.Name, Owner.Alias',
            'objectApiName' => 'CustomOpportunity__c',
            'icon' => 'Icon'
        };

        List<BadgeService.RecordWrapper> recordList = BadgeService.convertToWrappedRecords(records, config);

        Assert.isNotNull(recordList, 'Should not be null');
        Assert.areEqual(5, recordList.size(), 'List should contain 4 records');
        Assert.areEqual('Skal ansette', recordList[0].name, 'First field in columns should be set as Name');
        Assert.areEqual(records[0].Id, recordList[0].id, 'Record Id field should be set as id');
        Assert.areEqual(
            '/lightning/r/CustomOpportunity__c/' + records[0].Id + '/view',
            recordList[0].link,
            'Link should be set'
        );
        Assert.areEqual(config.get('icon'), recordList[0].icon, 'Icon should be set from config');
        Assert.isNotNull(recordList[0].fields, 'Should contain list of fields');
        Assert.areEqual('InquiryCategory__c', recordList[0].fields[0].fieldName);
        Assert.areEqual('InclusionStage__c', recordList[0].fields[1].fieldName);

        Assert.areEqual('Account__r_Name', recordList[0].fields[2].fieldName);
        Assert.areEqual('Owner_Alias', recordList[0].fields[3].fieldName);

        Assert.areEqual('Skal ansette', recordList[0].fields[0].value);
        Assert.areEqual('Ny henvendelse', recordList[0].fields[1].value);
    }

    @isTest
    static void validateQueryForPolymorphicFields() {
        Assert.areEqual(
            BadgeService.resolvePolymorphicOwnerField(
                'TYPEOF Owner WHEN User THEN Alias WHEN Group THEN Name END',
                'user'
            ),
            'Owner.Alias'
        );
        Assert.areEqual(
            BadgeService.resolvePolymorphicOwnerField(
                'TYPEOF Owner WHEN User THEN Alias WHEN Group THEN Name END',
                'group'
            ),
            'Owner.Name'
        );
    }

    @isTest
    static void validateLogicForFieldCreation() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        List<CustomOpportunity__c> records = [
            SELECT
                Id,
                InclusionStage__c,
                InquiryCategory__c,
                createddate,
                Account__r.Name,
                TYPEOF Owner
                    WHEN User THEN Alias
                    WHEN Group THEN Name
                END
            FROM CustomOpportunity__c
            WHERE
                InquiryCategory__c = 'Skal ansette'
                AND InclusionStage__c = 'Ny henvendelse'
                AND Account__c = :testAccount.Id
        ];

        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new List<String>{ 'CustomOpportunity__c' });
        Map<String, Schema.SObjectField> fieldData = descResult[0].fields.getMap();

        BadgeService.Field regularField = BadgeService.createFieldFromSObject(
            records[0],
            'InclusionStage__c',
            fieldData
        );
        Assert.isNotNull(regularField.label, 'Field should not be null');
        Assert.areEqual('InclusionStage__c', regularField.fieldName);
        Assert.areEqual(records[0].InclusionStage__c, regularField.value, 'Field value should match record value');

        BadgeService.Field lookupField = BadgeService.createFieldFromSObject(records[0], 'Account__r.Name', fieldData);
        Assert.isNotNull(lookupField.label, 'Field should not be null');
        Assert.areEqual('Account__r_Name', lookupField.fieldName);
        Assert.areEqual('c_reference', lookupField.type);
        BadgeService.RecordWrapper lookupRecord = (BadgeService.RecordWrapper) lookupField.value;
        Assert.areEqual(records[0].Account__r.Name, lookupRecord.name, 'Field value should match record value');
        Assert.isNotNull(lookupRecord.link, 'Link should not be null');
        Assert.areEqual(records[0].Account__r.Id, lookupRecord.id, 'Id should match record Id');
    }
}
