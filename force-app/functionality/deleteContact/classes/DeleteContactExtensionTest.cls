@IsTest
private class DeleteContactExtensionTest {
    @IsTest
    private static void testDeleteContact() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        List<Contact> contacts = TAG_TestDataFactory.createContacts(
            accounts,
            1
        );

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(
            contacts[0]
        );
        DeleteContactExtension dce = new DeleteContactExtension(sc);

        PageReference pageRef = Page.DeleteContact;
        Test.setCurrentPage(pageRef);
        String redirectUrl = dce.deleteContact().getUrl();

        Test.stopTest();
        List<Contact> deletedContacts = [SELECT Id FROM Contact];
        System.assertEquals(0, deletedContacts.size(), 'contact is deleted');
        System.assertEquals(
            '/' + accounts[0].Id,
            redirectUrl,
            'redirected to account'
        );
    }

    @IsTest
    private static void testCancelDeletion() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(1);
        List<Contact> contacts = TAG_TestDataFactory.createContacts(
            accounts,
            1
        );

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(
            contacts[0]
        );
        DeleteContactExtension dce = new DeleteContactExtension(sc);

        PageReference pageRef = Page.DeleteContact;
        Test.setCurrentPage(pageRef);
        String redirectUrl = dce.cancelDeletion().getUrl();

        Test.stopTest();
        System.assertEquals(
            '/' + contacts[0].Id,
            redirectUrl,
            'redirected back to contact'
        );
    }
}
