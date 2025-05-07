public with sharing class RelatedListConfigController {
    public class ColumnDefinition {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
    }

    public class RelatedListConfigResponse {
        @AuraEnabled public String relatedObjectApiName;  // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
        @AuraEnabled public List<String> columns; // Fields to return from database
        @AuraEnabled public String filter; // Query filter
        @AuraEnabled public String relationField;  // Field API name on related object that contains reference ID to the parent
        @AuraEnabled public String parentRelationField; // Field API name on parent object that contains the reference ID from "relationField"
        @AuraEnabled public String parentObjectApiName; // sObject API name of the parent
        @AuraEnabled public List<ColumnDefinition> columnDefinition;
        
    }
    @AuraEnabled(cacheable=true)
    public static RelatedListConfigResponse getConfig(String key) {
        System.debug(key);
        if (String.isEmpty(key)) {
            throw new AuraHandledException('Key cannot be null or empty');
        }

        RelatedListConfigResponse response = new RelatedListConfigResponse();
        RelatedListConfigFactory.RelatedListConfig config = RelatedListConfigFactory.getConfig(key);

        response.relatedObjectApiName = config.relatedObjectApiName;
        response.columns = config.columns;
        response.filter = config.filter;
        response.relationField = config.relationField;
        response.parentRelationField = config.parentRelationField;
        response.parentObjectApiName = config.parentObjectApiName;
        response.columnDefinition = buildColumnConfig(response.relatedObjectApiName, response.columns);
        System.debug('returning response: '+response);
        return response;
    }

 
    private static List<ColumnDefinition> buildColumnConfig(String relatedObjectApiName, List<String> columns) {
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(relatedObjectApiName).getDescribe().fields.getMap();
        List<ColumnDefinition> config = new List<ColumnDefinition>();
//   
for (String fieldName : columns) {
            ColumnDefinition col = new ColumnDefinition();
            if (fields.containsKey(fieldName)) {
                Schema.DescribeFieldResult f = fields.get(fieldName).getDescribe();
                col.label = f.getLabel();
                col.fieldName = fieldName;                
                col.type = mapFieldType(f.getType());                
                
            }else {
                System.debug('Field not found: ' + fieldName);
                col.label = fieldName;
                col.fieldName = fieldName;                
                
            }
            config.add(col);
        }
       
        return config;
    }

    private static String mapFieldType(Schema.DisplayType type) {
        switch on type {
            when Email       { return 'email'; }
            when Phone       { return 'phone'; }
            when Date        { return 'date'; }
            when DateTime    { return 'datetime'; }
            when Currency    { return 'currency'; }
            when Double      { return 'double'; }
            when Integer     { return 'number'; }
            when Boolean     { return 'boolean'; }
            when Picklist    { return 'text'; }
            when Address     { return 'address'; }
            when else        { return 'text'; }
        }
    }
} 