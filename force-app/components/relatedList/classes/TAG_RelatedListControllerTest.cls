@isTest
private class TAG_RelatedListControllerTest {
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
                    NumberOfWorkfare__c = 5,
                    OwnerId = arbeidsgiverUser.id
                )
            );
            arbeidsgiverUserAccounts.add(
                new Account(
                    Name = 'TestAccount1',
                    INT_OrganizationNumber__c = '9000000002',
                    INT_MunicipalityNumber__c = '3301',
                    TAG_Partner_Status__c = null,
                    NumberOfWorkfare__c = 0,
                    OwnerId = arbeidsgiverUser.id
                )
            );
            insert arbeidsgiverUserAccounts;

        List<CustomOpportunity__c> arbeidsgiverUserOpportunities = TAG_TestDataFactory.getCustomOpportunities(
                3,
                false
            );
            Integer i = 0;
            for (CustomOpportunity__c opp : arbeidsgiverUserOpportunities) {
                opp.Account__c = arbeidsgiverUserAccounts[0].Id;
                opp.OwnerId = arbeidsgiverUser.id;
                opp.InclusionStage__c = 'Ny henvendelse';
                opp.InquiryCategory__c = 'Skal ansette';
            }
            insert arbeidsgiverUserOpportunities;

        Contact con = new Contact(
            TAG_Informed__c = true,
            LastName = 'test',
            FirstName = 'test',
            Source__c = 'Permittering',
            Email = 'test@domain.com',
            AccountId = arbeidsgiverUserAccounts[0].Id
        );
        insert con;  
        }  
    }
    @isTest
    static void testGetRelatedList_ReturnContacts() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        List<String> fieldNames = new List<String>{ 'Id', 'FirstName', 'LastName', 'TAG_Informed__c', 'AccountId' };
        String parentId               = acct.Id;
        String objectApiName          = 'Contact';
        String relationField          = 'AccountId';
        String parentRelationField    = 'Id';
        String parentObjectApiName    = 'Account';
        String filterConditions       = 'TAG_Informed__c = true';
        
        Test.startTest();
        List<SObject> results = TAG_RelatedListController.getRelatedList(
            fieldNames,
            parentId,
            objectApiName,
            relationField,
            parentRelationField,
            parentObjectApiName,
            filterConditions
        );
        Test.stopTest();
        
        System.assertEquals(
            1, 
            results.size(), 
            'Expected exactly one Contact under TestAccount0.'
        );
        
        Contact fetchedCon = (Contact) results[0];
        System.assertEquals('test', fetchedCon.FirstName,  'FirstName should be "test"');
        System.assertEquals('test', fetchedCon.LastName,   'LastName should be "test"');
        System.assertEquals(
            true, 
            fetchedCon.TAG_Informed__c, 
            'TAG_Informed__c should be true for the returned record.'
        );
        System.assertEquals(
            acct.Id, 
            fetchedCon.AccountId, 
            'AccountId on the returned Contact should match TestAccount0.Id.'
        );
    }
    @isTest
    static void testGetRelatedList_ReturnCustomOpportunities() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'TestAccount0' LIMIT 1];

        List<String> fieldNames = new List<String>{
            'Id', 
            'Name', 
            'InclusionStage__c', 
            'InquiryCategory__c',
            'Account__c'
        };
        String parentId               = acct.Id;
        String objectApiName          = 'CustomOpportunity__c';
        String relationField          = 'Account__c';
        String parentRelationField    = 'Id';
        String parentObjectApiName    = 'Account';
        String filterConditions       = 'InquiryCategory__c = \'Skal ansette\'';
        
        Test.startTest();
        List<SObject> oppResults = TAG_RelatedListController.getRelatedList(
            fieldNames,
            parentId,
            objectApiName,
            relationField,
            parentRelationField,
            parentObjectApiName,
            filterConditions
        );
        Test.stopTest();
        
        System.assertEquals(
            3,
            oppResults.size(),
            'Expected three CustomOpportunity__c records with InquiryCategory__c = "Skal ansette" under TestAccount0.'
        );
        
        for (SObject sobj : oppResults) {
            CustomOpportunity__c fetchedOpp = (CustomOpportunity__c) sobj;
            System.assertEquals(
                'Skal ansette',
                fetchedOpp.InquiryCategory__c,
                'Each returned CustomOpportunity__c record should have InquiryCategory__c = "Skal ansette".'
            );
            System.assertEquals(
                acct.Id,
                fetchedOpp.Account__c,
                'Each returned CustomOpportunity__c should refer to the same Account (TestAccount0).'
            );
        }
    }
}