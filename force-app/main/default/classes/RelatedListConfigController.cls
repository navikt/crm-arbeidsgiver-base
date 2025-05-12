public with sharing class RelatedListConfigController {
    public class Record{
        @AuraEnabled public String name;
        @AuraEnabled public String id;
        @AuraEnabled public String link;
        @AuraEnabled public List<Field> fields; // Field metadata
        //@AuraEnabled public Map<String, Object> fieldValues; // Field values   
    }
    public class Field{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public Object value;
    }

 
    @AuraEnabled(cacheable=true)
    public static List<Record> getRecords(String objectApiName, String columns, String relationshipField, String parentRecordId, String filter) {
        //  columns = new List<String>{'Id', 'Name', 'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'Is_My_Region__c'};  
        // List<SObject> records = getRecords('JobPosting__c', columns, 'Account__c', key, 'CreatedDate = LAST_N_DAYS:30');
        List<SObject> records = getRecordData(objectApiName, columns, relationshipField, parentRecordId, 'CreatedDate = LAST_N_DAYS:30');
        List<Record> recordsWithFields = createListOfRecords(records, objectApiName, columns);
        return recordsWithFields;
    }


    private static List<SObject> getRecordData(String objectApiName, String columns,String relationshipField, String parentRecordId, String filter) {
       
        List<SObject> records = new List<SObject>();
        String query = 'SELECT '+columns.toString()+' FROM ' + objectApiName;
        query +=' WHERE  '+relationshipField+' = \'' + parentRecordId + '\'';
        if (String.isNotBlank(filter)) {
            query += ' AND ' + filter;
        }
         System.debug('query: '+query);
        records = Database.query(query);
        return records;
    }

    private static List<Record> createListOfRecords(List<SObject> records, String objectApiName, String columnsStr) {
        List<String> columns = columnsStr.replace(' ', '').split(',');
        Map<String, Schema.SObjectField> fieldData = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        List<Field> config = new List<Field>();

        List<Record> recordList = new List<Record>();
        for (SObject record : records) {
            Record rec = new Record();
            rec.name = (String)record.get('Name');
            rec.id = (String)record.get('Id');
            
            rec.fields = new List<Field>();
            for (String fieldName : columns) {
                Field col = new Field();
                if (fieldData.containsKey(fieldName)) {
                    Schema.DescribeFieldResult f = fieldData.get(fieldName).getDescribe();
                    col.label = f.getLabel();
                    col.fieldName = fieldName;                
                    col.type = mapFieldType(f.getType());
                    col.value = record.get(fieldName);                  
                    
                }else {
                    System.debug('Field not found: ' + fieldName);
                    col.label = fieldName;
                    col.fieldName = fieldName;                
                    
                }
                rec.fields.add(col);
            }


            recordList.add(rec);
        }
        return recordList;
    }





    private static List<Field> createFieldDefinition(String objectApiName, List<String> columns) {
        Map<String, Schema.SObjectField> fieldData = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        List<Field> config = new List<Field>();
//   
        for (String fieldName : columns) {
            Field col = new Field();
            if (fieldData.containsKey(fieldName)) {
                Schema.DescribeFieldResult f = fieldData.get(fieldName).getDescribe();
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