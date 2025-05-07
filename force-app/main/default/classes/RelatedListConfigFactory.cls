public class RelatedListConfigFactory {
    public class RelatedListConfig {
        public String relatedObjectApiName;  // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
        public List<String> columns; // Fields to return from database
        public String filter; // Query filter
        public String relationField;  // Field API name on related object that contains reference ID to the parent
        public String parentRelationField; // Field API name on parent object that contains the reference ID from "relationField"
        public String parentObjectApiName; // sObject API name of the parent

        public RelatedListConfig(String relatedObjectApiName, List<String> columns, String filter, String relationField, String parentRelationField, String parentObjectApiName) {
            this.relatedObjectApiName = relatedObjectApiName;
            this.columns = columns;
            this.filter = filter;
            this.relationField = relationField;
            this.parentRelationField = parentRelationField;
            this.parentObjectApiName = parentObjectApiName;
        }
    }

    @TestVisible private static final Map<String, RelatedListConfig> CONFIGS = new Map<String, RelatedListConfig>{
        'AccountContacts' => new RelatedListConfig('Contact', new List<String>{'Name', 'Title', 'Email', 'MobilePhone'}, 'TAG_Former_Employee__c = false', 'AccountId', 'Id', 'Account'),
        'AccountAccountTeamMembers'    => new RelatedListConfig('AccountTeamMember', new List<String>{'User.Name', 'TeamMemberRole', 'User.CompanyName', 'User.MobilePhone'}, null, 'AccountId', 'Id','Account'),
        'AccountContracts'    => new RelatedListConfig('Contract__c', new List<String>{'TAG_Link__c', 'Region__c', 'TAG_StartDate__c', 'TAG_EndDate__c','TAG_Status__c'}, 'RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY', 'TAG_Account__c', 'Id','Account')
        
        // ...more
    };

    public static RelatedListConfig getConfig(String key) {
        System.debug('key: '+key);
        if (!CONFIGS.containsKey(key)) {
            throw new AuraHandledException('Unknown config key: ' + key);
        }
        return CONFIGS.get(key);
    }
}