@isTest
private without sharing class AccessControlValidatorTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER USER',
            new List<String>{
                'Arbeidsgiver_arenaActivity',
                'Arbeidsgiver_base',
                'Arbeidsgiver_contract',
                'Arbeidsgiver_opportunity',
                'Arbeidsgiver_temporaryLayoffs'
            }
        );
    }

    @isTest
    private static void testSObjectIsAccessible_emptyUser() {
        User u = TAG_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.sObjectIsAccessible('TemporaryLayoff__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testSObjectIsAccessible_emptyUserWithPermset() {
        User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.sObjectIsAccessible('TemporaryLayoff__c');
        }
        Test.StopTest();

        System.assert(result, 'New user should have access');
    }

    @isTest
    private static void testSObjectIsCreateable_emptyUser() {
        User u = TAG_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.sObjectIsCreateable('CustomOpportunity__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testSObjectIsCreateable_emptyUserWithPermset() {
        User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.sObjectIsCreateable('CustomOpportunity__c');
        }
        Test.StopTest();

        System.assert(result, 'New user should have access');
    }

    @isTest
    private static void testFieldIsAccessible_emptyUser() {
        User u = TAG_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.fieldIsAccessible('Task', 'RelatedToAccount__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testFieldIsAccessible_emptyUserWithPermset() {
        User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.fieldIsAccessible('Task', 'RelatedToAccount__c');
        }
        Test.StopTest();

        System.assert(result, 'New user should have access');
    }

    @isTest
    private static void testFieldIsCreateable_emptyUser() {
        User u = TAG_TestDataFactory.createStandardUser('ARBEIDSGIVER USER');
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.fieldIsCreateable('Task', 'RelatedToAccount__c');
        }
        Test.StopTest();

        System.assert(!result, 'Empty user user should NOT have access');
    }

    @isTest
    private static void testFieldIsCreateable_emptyUserWithPermset() {
        User u = [SELECT Id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        Boolean result;

        Test.StartTest();
        System.runAs(u) {
            result = AccessControlValidator.fieldIsCreateable('Task', 'RelatedToAccount__c');
        }
        Test.StopTest();

        System.assert(result, 'New user should have access');
    }
}
