@isTest
private without sharing class BankAccountControllerTest {
    @isTest
    private static void testGetBankAccountNumber() {
        Account acc = new Account(Name = 'test', INT_OrganizationNumber__c = '99999999');
        insert acc;

        SingleRequestMock mock = new SingleRequestMock(200, 'Success', getMockData(), new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.StartTest();
        BankAccountModel actual = BankAccountController.getBankAccountNumber(acc.Id);
        Test.StopTest();

        System.assertEquals(
            '8361347234732292',
            actual.kontonr,
            'should have fetched the correct account number from the mock api'
        );
        System.assertEquals(true, actual.isSuccess, 'should be a success');
    }

    @isTest
    private static void testGetBankAccountNumber_error() {
        Account acc = new Account(Name = 'test', INT_OrganizationNumber__c = '99999999');
        insert acc;

        SingleRequestMock mock = new SingleRequestMock(404, 'Success', getErrorMockData(), new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.StartTest();
        BankAccountModel actual = BankAccountController.getBankAccountNumber(acc.Id);
        Test.StopTest();

        System.assertEquals(
            'Organisasjonsnummer ikke funnet i kontoregister',
            actual.feilmelding,
            'should have fetched the correct account number from the mock api'
        );
        System.assertEquals(false, actual.isSuccess, 'should NOT be a success');
    }

    @isTest
    private static void testQueryKontonummer() {
        SingleRequestMock mock = new SingleRequestMock(200, 'Success', getMockData(), new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.StartTest();
        BankAccountModel actual = BankAccountController.queryKontonummer('99999999');
        Test.StopTest();

        System.assertEquals(
            '8361347234732292',
            actual.kontonr,
            'should have fetched the correct account number from the mock api'
        );
    }

    private static String getMockData() {
        return '{"mottaker": "990983666","kontonr": "8361347234732292"}';
    }

    private static String getErrorMockData() {
        return '{"feilmelding": "Organisasjonsnummer ikke funnet i kontoregister"}';
    }
}
