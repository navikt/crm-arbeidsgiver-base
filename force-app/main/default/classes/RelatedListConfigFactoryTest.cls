@isTest
private class RelatedListConfigFactoryTest {
      

    @IsTest
    static void testAllConfigVariants() {
        List<String> allKeys = new List<String>();
        allKeys.addAll(RelatedListConfigFactory.CONFIGS.keySet());
        
        for (String key : allKeys) {
            Test.startTest();
            RelatedListConfigFactory.RelatedListConfig config = RelatedListConfigFactory.getConfig(key);
            System.assertNotEquals(null, config, 'Config should not be null for key: ' + key);
            System.assert(!String.isEmpty(config.relatedObjectApiName), 'relatedObject must be defined');
            System.assert(config.columns.size() > 0, 'At least one column must be defined');
            Test.stopTest();
        }
    }

    @IsTest
    static void testUnknownKeyThrows() {
        try {
            RelatedListConfigFactory.getConfig('Unknown_Key');
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Unknown config key'));
        }
    }
}