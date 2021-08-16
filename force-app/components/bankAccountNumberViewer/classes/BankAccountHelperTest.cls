@isTest
private without sharing class BankAccountHelperTest {
    @isTest
    private static void testSaveResults_200() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(
                200,
                'Success',
                BankAccountControllerTest.getMockData_200(),
                new Map<String, String>()
            )
        );

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('', '');
        apiCtrl.doCallout();

        Test.StartTest();
        BankAccountModel actual = BankAccountHelper.saveResults(apiCtrl);
        Test.StopTest();

        System.assertEquals(true, actual.isSuccess, 'should be a success');
        System.assertEquals('8361347234732292', actual.kontonr, 'should be set to konto nr');
        System.assertEquals('990983666', actual.mottaker, 'should be set to org no');
    }

    @isTest
    private static void testSaveResults_400() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(400, 'Error', BankAccountControllerTest.getMockData_400(), new Map<String, String>())
        );

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('', '');
        apiCtrl.doCallout();

        Test.StartTest();
        BankAccountModel actual = BankAccountHelper.saveResults(apiCtrl);
        Test.StopTest();

        System.assertEquals(false, actual.isSuccess, 'should be error');
        System.assertEquals(
            'Feil! Vennligst kontakt en administrator.',
            actual.feilmelding,
            'should be set to default error message because HTTP error 400 is not implemented by the api'
        );
        System.assertEquals(null, actual.kontonr, 'should be null');
        System.assertEquals(null, actual.mottaker, 'should be null');
    }

    @isTest
    private static void testSaveResults_404() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(404, 'Error', BankAccountControllerTest.getMockData_404(), new Map<String, String>())
        );

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('', '');
        apiCtrl.doCallout();

        Test.StartTest();
        BankAccountModel actual = BankAccountHelper.saveResults(apiCtrl);
        Test.StopTest();

        System.assertEquals(false, actual.isSuccess, 'should be error');
        System.assertEquals(
            'Organisasjonsnummer ikke funnet i kontoregister',
            actual.feilmelding,
            'should be set to error message'
        );
        System.assertEquals(null, actual.kontonr, 'should be null');
        System.assertEquals(null, actual.mottaker, 'should be null');
    }

    @isTest
    private static void testValidStatusCode_200() {
        Test.StartTest();
        Boolean actual = BankAccountHelper.validStatusCode(200);
        Test.StopTest();

        System.assertEquals(true, actual, '200 is a valid status code');
    }

    @isTest
    private static void testValidStatusCode_404() {
        Test.StartTest();
        Boolean actual = BankAccountHelper.validStatusCode(404);
        Test.StopTest();

        System.assertEquals(true, actual, '404 is a valid status code');
    }

    @isTest
    private static void testValidStatusCode_405() {
        Test.StartTest();
        Boolean actual = BankAccountHelper.validStatusCode(405);
        Test.StopTest();

        System.assertEquals(true, actual, '405 is a valid status code');
    }

    @isTest
    private static void testValidStatusCode_500() {
        Test.StartTest();
        Boolean actual = BankAccountHelper.validStatusCode(500);
        Test.StopTest();

        System.assertEquals(true, actual, '500 is a valid status code');
    }

    @isTest
    private static void testValidStatusCode_400() {
        Test.StartTest();
        Boolean actual = BankAccountHelper.validStatusCode(400);
        Test.StopTest();

        System.assertEquals(false, actual, '400 is NOT a valid status code in the api');
    }

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
