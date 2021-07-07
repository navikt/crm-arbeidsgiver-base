@isTest
private without sharing class BankAccountHelperTest {
    @isTest
    private static void testGetOrgNo() {
        Account acc = new Account(Name = 'test', INT_OrganizationNumber__c = '99999999');
        insert acc;

        Test.StartTest();
        String actual = BankAccountHelper.getOrgNo(acc.Id);
        Test.StopTest();

        System.assertEquals('99999999', actual, 'should have fetched the correct INT_OrganizationNumber__c');
    }

    @isTest
    private static void testGetOrgNo_wrongId() {
        Test.StartTest();
        try {
            BankAccountHelper.getOrgNo(null);
            System.assert(false, 'Non-correct assertion, the code did NOT give an exception successfully');
        } catch (Exception e) {
            System.assert(true, 'Correct assertion, the code gave an exception successfully');
        }
        Test.StopTest();
    }

    @isTest
    private static void testGetOrgNo_noOrgNo() {
        Account acc = new Account(Name = 'test');
        insert acc;

        Test.StartTest();
        try {
            BankAccountHelper.getOrgNo(acc.Id);
            System.assert(false, 'Non-correct assertion, the code did NOT give an exception successfully');
        } catch (Exception e) {
            System.assert(true, 'Correct assertion, the code gave an exception successfully');
        }
        Test.StopTest();
    }
}
