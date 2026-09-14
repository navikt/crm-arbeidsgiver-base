@IsTest(SeeAllData=false)
private class TAG_UserOfficeHeaderControllerTest {
    private static final String NAV_UNIT_NAME = 'NAV Test Office';
    @TestSetup
    static void makeData() {
        insert new NavUnit__c(Name = NAV_UNIT_NAME);
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenMatchingCompanyName_whenGetNavUnitByCompanyName_thenNavUnitReturned() {
        TAG_TestDataFactory.createUserWithPermset('ARBEIDSGIVER USER', new List<String>{ 'Arbeidsgiver_base' });
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        String result;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            result = TAG_UserOfficeHeaderController.getNavUnitIdByCompanyName(NAV_UNIT_NAME);
            Test.stopTest();
        }
        Assert.isNotNull(result, 'A matching NavUnit should be returned');
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenNoMatchingCompanyName_whenGetNavUnitByCompanyName_thenNullReturned() {
        TAG_TestDataFactory.createUserWithPermset('ARBEIDSGIVER USER', new List<String>{ 'Arbeidsgiver_base' });
        User arbeidsgiverUser = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER USER' LIMIT 1];
        String result;
        System.runAs(arbeidsgiverUser) {
            Test.startTest();
            result = TAG_UserOfficeHeaderController.getNavUnitIdByCompanyName('Does Not Exist');
            Test.stopTest();
        }

        Assert.isNull(result, 'No NavUnit should be returned for a non-matching company name');
    }

    // Code-analyzer-suppress(pmd:MethodNamingConventions)
    @IsTest
    static void givenNoAccess_whenGetNavUnitByCompanyName_thenNullReturned() {
        TAG_TestDataFactory.createUserWithPermset('OTHER USER', new List<String>{});
        User otherUser = [SELECT id FROM User WHERE LastName = 'OTHER USER' LIMIT 1];
        String resultNoAccess;
        System.runAs(otherUser) {
            Test.startTest();
            resultNoAccess = TAG_UserOfficeHeaderController.getNavUnitIdByCompanyName(NAV_UNIT_NAME);
            Test.stopTest();
        }
        Assert.isNull(resultNoAccess, 'No NavUnit should be returned when the user has no access');
        Assert.isNull(
            TAG_UserOfficeHeaderController.getNavUnitIdByCompanyName(''),
            'A blank company name should return null without querying'
        );
    }
}
