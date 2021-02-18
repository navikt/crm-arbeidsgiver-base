@isTest
private without sharing class Contact_InvalidEmailRemovalTest {
    @testSetup
    private static void setup() {
    }

    @isTest
    private static void testRemoveInvalidEmail() {
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test', InvalidEmail__c = 'test@feilepost');
        insert c;

        c = [SELECT Id, InvalidEmail__c, Email FROM Contact WHERE Id = :c.Id LIMIT 1];
        System.assertEquals(
            'test@feilepost',
            c.InvalidEmail__c,
            'Invalid email should be null after adding correct email'
        );
        System.assertEquals(null, c.Email, 'Email should be null after not adding anything');

        c.Email = 'correct@email.com';
        update c;

        Test.StartTest();
        Test.StopTest();

        c = [SELECT Id, InvalidEmail__c, Email FROM Contact WHERE Id = :c.Id LIMIT 1];
        System.assertEquals(null, c.InvalidEmail__c, 'Invalid email should be null after adding correct email');
        System.assertEquals('correct@email.com', c.Email, 'Email should not be null after adding valid email');
    }

    @isTest
    private static void testRemoveInvalidEmail_updateWithInvalidEmail() {
        Contact c = new Contact(TAG_Informed__c = true, LastName = 'test', InvalidEmail__c = 'test@feilepost');
        insert c;

        c = [SELECT Id, InvalidEmail__c, Email FROM Contact WHERE Id = :c.Id LIMIT 1];
        System.assertEquals(
            'test@feilepost',
            c.InvalidEmail__c,
            'Invalid email should not be null after adding correct email'
        );
        System.assertEquals(null, c.Email, 'Email should be null after not adding anything');

        c.Email = 'test@feilepost2';
        Database.update(c, false);

        Test.StartTest();
        Test.StopTest();

        c = [SELECT Id, InvalidEmail__c, Email FROM Contact WHERE Id = :c.Id LIMIT 1];
        System.assertEquals(
            'test@feilepost',
            c.InvalidEmail__c,
            'Invalid email should still be same value as the new email is invalid'
        );
        System.assertEquals(null, c.Email, 'Email should be null after adding invalid email');
    }
}
