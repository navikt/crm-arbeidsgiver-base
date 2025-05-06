public class RelatedListConfigFactory {
    public class RelatedListConfig {
        public String objectApiName;
        public List<String> columns;
        public String filter;
        public RelatedListConfig(String objectApiName, List<String> columns, String filter) {
            this.objectApiName = objectApiName;
            this.columns = columns;
            this.filter = filter;
        }
    }

    @TestVisible
    private static final Map<String, RelatedListConfig> CONFIGS = new Map<String, RelatedListConfig>{
        'Account_Contacts' => new RelatedListConfig('Contact', new List<String>{'Name','Email'}, 'AccountId = :recordId'),
        'Account_Cases'    => new RelatedListConfig('Case', new List<String>{'Subject','Status'}, 'AccountId = :recordId')
        // ...more
    };

    public static RelatedListConfig getConfig(String key) {
        if (!CONFIGS.containsKey(key)) {
            throw new AuraHandledException('Unknown config key: ' + key);
        }
        return CONFIGS.get(key);
    }
}