public with sharing class RelatedListConfigController {
    public class ColumnDefinition {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
    }

    public class RelatedListConfigResponse {
        @AuraEnabled public List<String> columns;
        @AuraEnabled public String filter;
        @AuraEnabled public List<ColumnDefinition> columnConfig; 
    }

    @AuraEnabled(cacheable=true)
    public static RelatedListConfigResponse getConfig(String key) {
        RelatedListConfigFactory.RelatedListConfig config = RelatedListConfigFactory.getConfig(key);

        RelatedListConfigResponse response = new RelatedListConfigResponse();
        response.columns = config.columns;
        response.filter = config.filter;
        response.columnConfig = buildColumnConfig(config.relatedObjectApiName, config.columns);
        return response;
    }

    private static List<ColumnDefinition> buildColumnConfig(String relatedObjectApiName, List<String> columns) {
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(relatedObjectApiName).getDescribe().fields.getMap();
        List<ColumnDefinition> config = new List<ColumnDefinition>();
// 
        for (String fieldName : columns) {
            if (fields.containsKey(fieldName)) {
                Schema.DescribeFieldResult f = fields.get(fieldName).getDescribe();
                ColumnDefinition col = new ColumnDefinition();
                col.label = f.getLabel();
                col.fieldName = fieldName;
                col.type = mapFieldType(f.getType());
                config.add(col);
            }
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