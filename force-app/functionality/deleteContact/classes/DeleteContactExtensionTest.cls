@IsTest
private class DeleteContactExtensionTest {
    @IsTest
    private static void testDeleteContact() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        List<Contact> contacts = TAG_TestDataFactory.createContacts(accounts, 1);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(contacts[0]);
        DeleteContactExtension dce = new DeleteContactExtension(sc);

        PageReference pageRef = Page.DeleteContact;
        Test.setCurrentPage(pageRef);
        String redirectUrl = dce.deleteContact().getUrl();

        Test.stopTest();
        List<Contact> deletedContacts = [SELECT Id FROM Contact];
        System.assertEquals(0, deletedContacts.size(), 'contact is deleted');
        System.assertEquals('/' + accounts[0].Id, redirectUrl, 'redirected to account');
    }
    @IsTest
    private static void testDeleteContactWithoutDeletingTaskEvent() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        List<Contact> contacts = TAG_TestDataFactory.createContacts(accounts, 2);

        Event e1 = new Event(
            TAG_NoPersonInformation__c = true,
            WhatId = accounts[0].Id,
            DurationInMinutes = 1440,
            IsAllDayEvent = true,
            ActivityDate = Date.today(),
            TAG_ActivityType__c = 'Nedbemanne',
            Subject = 'Hele dagen',
            WhoId = contacts[0].Id
        );
        insert e1;

        Event e2 = new Event(
            TAG_NoPersonInformation__c = true,
            WhatId = accounts[0].Id,
            DurationInMinutes = 1440,
            IsAllDayEvent = true,
            ActivityDate = Date.today(),
            TAG_ActivityType__c = 'Nedbemanne',
            Subject = 'Hele dagen',
            WhoId = contacts[1].Id
        );
        insert e2;

        Task t1 = new Task(
            TAG_NoPersonInformation__c = true,
            WhatId = accounts[0].Id,
            ActivityDate = Date.today(),
            Subject = 'test',
            WhoId = contacts[0].Id
        );
        insert t1;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(contacts[0]);
        DeleteContactExtension dce = new DeleteContactExtension(sc);

        PageReference pageRef = Page.DeleteContact;
        Test.setCurrentPage(pageRef);
        String redirectUrl = dce.deleteContact().getUrl();

        Test.stopTest();
        List<Contact> deletedContacts = [SELECT Id FROM Contact];
        String event1WhoId = [SELECT Id, WhoId FROM Event WHERE Id = :e1.Id].WhoId;
        String event2WhoId = [SELECT Id, WhoId FROM Event WHERE Id = :e2.Id].WhoId;
        String task1WhoId = [SELECT Id, WhoId FROM Task WHERE Id = :t1.Id].WhoId;

        System.assertEquals(null, event1WhoId, 'WhoId field should be null');
        System.assertEquals(e2.WhoId, event2WhoId, 'WhoId field should be unchanged');
        System.assertEquals(null, task1WhoId, 'WhoId field should be null');
        System.assertEquals(1, deletedContacts.size(), 'only 1 contact is not deleted');
        System.assertEquals('/' + accounts[0].Id, redirectUrl, 'redirected to account');
    }

    @IsTest
    private static void testCancelDeletion() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        List<Contact> contacts = TAG_TestDataFactory.createContacts(accounts, 1);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(contacts[0]);
        DeleteContactExtension dce = new DeleteContactExtension(sc);

        PageReference pageRef = Page.DeleteContact;
        Test.setCurrentPage(pageRef);
        String redirectUrl = dce.cancelDeletion().getUrl();

        Test.stopTest();
        System.assertEquals('/' + contacts[0].Id, redirectUrl, 'redirected back to contact');
    }
}
