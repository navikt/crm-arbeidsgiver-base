@isTest
private without sharing class TAG_TestDataFactoryTest {
    @isTest
    private static void testcreateStandardUser() {
        Integer beforeUser = [SELECT Id FROM User].size();

        Test.StartTest();
        TAG_TestDataFactory.createStandardUser('Last UNIQUE NAME');
        Test.StopTest();

        Integer afterUser = [SELECT Id FROM User].size();

        System.assertEquals(
            1,
            afterUser - beforeUser,
            'New user should have been created'
        );
    }

    @isTest
    private static void testGetOwnerForAccounts() {
        Integer beforeUser = [SELECT Id FROM User].size();

        Test.StartTest();
        TAG_TestDataFactory.getOwnerForAccounts();
        Test.StopTest();

        Integer afterUser = [SELECT Id FROM User].size();

        System.assertEquals(
            1,
            afterUser - beforeUser,
            'New user should have been created'
        );
    }

    @isTest
    private static void testCreateAccounts() {
        Integer beforeAccount = [SELECT Id FROM Account].size();
        Integer amount = 4;
        Test.StartTest();
        TAG_TestDataFactory.createAccounts(amount);
        Test.StopTest();

        Integer afterAccount = [SELECT Id FROM Account].size();

        System.assertEquals(
            amount,
            afterAccount - beforeAccount,
            'New user should have been created'
        );
    }

    @IsTest
    private static void getCustomOpportunities() {
        Integer amount = 4;
        Test.StartTest();
        TAG_TestDataFactory.getCustomOpportunities(4, true);
        Test.StopTest();

        Integer afterOpportunity = [SELECT Id FROM CustomOpportunity__c].size();

        System.assertEquals(
            amount,
            afterOpportunity,
            'New opportunities should have been created'
        );
    }

    @IsTest
    private static void testGetTemporaryLayoffs() {
        Account acc = TAG_TestDataFactory.createAccounts(1)[0];
        update acc;
        Integer amount = 4;
        Test.StartTest();
        TAG_TestDataFactory.getTemporaryLayoffs(4, acc, true);
        Test.StopTest();

        Integer afterLayoffs = [SELECT Id FROM TemporaryLayoff__c].size();

        System.assertEquals(
            amount,
            afterLayoffs,
            'New layoffs should have been created'
        );
    }

    @IsTest
    private static void testAssignPermissionSet() {
        Test.startTest();
        TAG_TestDataFactory.assignPermissionSet(
            'testgfd899@nav.test',
            'ManageAccounts'
        );
        Test.stopTest();

        List<User> users = [
            SELECT Id
            FROM User
            WHERE Username = 'testgfd899@nav.test'
        ];
        System.assertEquals(1, users.size(), 'User is not created');
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'ManageAccounts'
        ];
        System.assertEquals(
            1,
            permissionSets.size(),
            'Permission set is not created'
        );

        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE
                AssigneeId = :users[0].Id
                AND PermissionSetId = :permissionSets[0].Id
        ];
        System.assertEquals(
            1,
            PermissionSetAssignments.size(),
            'Permission set is not assigned to new user'
        );
    }

    @IsTest
    private static void testCreateUserWithPermset() {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :'Arbeidsgiver_base'
            LIMIT 1
        ];
        System.assertNotEquals(null, ps, 'permset should exist');

        List<User> u = [SELECT Id FROM User WHERE LastName = 'LAST NAME'];
        System.assertEquals(
            0,
            u.size(),
            'function should NOT have created one user'
        );

        Test.StartTest();
        TAG_TestDataFactory.createUserWithPermset(
            'LAST NAME',
            'Arbeidsgiver_base'
        );
        Test.StopTest();

        u = [SELECT Id FROM User WHERE LastName = 'LAST NAME'];
        System.assertEquals(
            1,
            u.size(),
            'function should have created one user'
        );

        List<PermissionSetAssignment> permsetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u[0].Id AND PermissionSetId = :ps.Id
        ];
        System.assertEquals(
            1,
            permsetAssignments.size(),
            'one assignments added'
        );
    }

    @IsTest
    private static void testCreateUserWithPermset_multiple() {
        List<String> permsetNames = new List<String>{
            'Arbeidsgiver_arenaActivity',
            'Arbeidsgiver_base',
            'Arbeidsgiver_contract',
            'Arbeidsgiver_opportunity',
            'Arbeidsgiver_temporaryLayoffs'
        };

        List<PermissionSet> permsets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :permsetNames
        ];
        Set<Id> permsetIds = new Map<Id, PermissionSet>(permsets).keySet();
        System.assertEquals(5, permsets.size(), 'permsets should exist');

        List<User> u = [SELECT Id FROM User WHERE LastName = 'LAST NAME'];
        System.assertEquals(
            0,
            u.size(),
            'function should NOT have created one user'
        );

        Test.StartTest();
        TAG_TestDataFactory.createUserWithPermset('LAST NAME', permsetNames);
        Test.StopTest();

        u = [SELECT Id FROM User WHERE LastName = 'LAST NAME'];
        System.assertEquals(
            1,
            u.size(),
            'function should have created one user'
        );

        List<PermissionSetAssignment> permsetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u[0].Id AND PermissionSetId IN :permsetIds
        ];
        System.assertEquals(
            5,
            permsetAssignments.size(),
            'five assignments added'
        );
    }

    @IsTest
    private static void testCreateContacts() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(2);
        Test.startTest();
        List<Contact> contacts = TAG_TestDataFactory.createContacts(
            accounts,
            3
        );
        Test.stopTest();
        System.assertEquals(
            6,
            contacts.size(),
            'three contacts per account added'
        );
    }
}
