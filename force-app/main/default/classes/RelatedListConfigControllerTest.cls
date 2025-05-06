@isTest
private class RelatedListConfigControllerTest {
    /**
    @isTest
    static void testGetConfig() {
        Test.startTest();
        RelatedListConfigController.RelatedListConfigResponse result = RelatedListConfigController.getConfig('recentContacts');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(4, result.columns.size());
        System.assertEquals('CreatedDate = LAST_N_DAYS:30', result.filter);
        System.assertEquals('email', result.columnConfig.stream().filter(c -> c.fieldName == 'Email').findFirst().orElse(null)?.type);
    }
         */
}
