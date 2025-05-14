public with sharing class RelatedListConfigController {
    public class Record{
        @AuraEnabled public String name;
        @AuraEnabled public String id;
        @AuraEnabled public String link;
        @AuraEnabled public List<Field> fields; // Field metadata
    }
    public class Field{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public Object value;
        @AuraEnabled public Map<String,Object> typeAttributes;
    }

 
    @AuraEnabled(cacheable=true)
    public static List<Record> getRecords(String objectApiName, String columns, String relationshipField, String parentRecordId, String filter) {
        System.debug('filter: '+filter);
        List<SObject> records = getRecordData(objectApiName, columns, relationshipField, parentRecordId, filter);
        System.debug('Record: '+records);
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
            rec.name = (String)record.get(columns[0]);
            rec.id = (String)record.get('Id');         
            rec.link = '/' + rec.id;
             

            // Create fields
            rec.fields = new List<Field>();
            for (String fieldName : columns) {

                Field col = new Field();
                if (fieldData.containsKey(fieldName)) {
                    Schema.DescribeFieldResult f = fieldData.get(fieldName).getDescribe();
                    col.label = f.getLabel();
                    col.fieldName = fieldName;                
                    col.type = mapFieldType(f);
                    col.typeAttributes = createTypeAttributes(f.getType());
                    col.value = record.get(fieldName);                  
                    
                }else {
                    System.debug('Field not found: ' + fieldName);
                    col.label = fieldName;
                    col.fieldName = fieldName;                
                    
                }
                rec.fields.add(col);
            }

            // Add record to list
            recordList.add(rec);
        }
        return recordList;
    }



    private static String mapFieldType(Schema.DescribeFieldResult field) {
        if(field.getType()==Schema.DisplayType.STRING && field.isHtmlFormatted()){
            return 'customRichText';
        }
        Schema.DisplayType type=field.getType();
        switch on type {
            when Email       { return 'email'; }
            when Phone       { return 'phone'; }
            when Date        { return 'date'; }
            when DateTime    { return 'date'; }
            when Double      { return 'number'; }
            when Integer     { return 'number'; }
            when Boolean     { return 'boolean'; }
            when Picklist    { return 'text'; }
            when Address     { return 'address'; }
            when String      { return 'text'; }
            when else        { return 'text'; }
        }
    }

    private static Map<String,Object> createTypeAttributes(Schema.DisplayType type) {
        Map<String,Object> typeAttributes = new Map<String,Object>();
         switch on type {
            when String       { typeAttributes.put('linkify',true);}
            when Datetime     { typeAttributes.put('year', 'numeric');
                                typeAttributes.put('month', '2-digit');
                                typeAttributes.put('day', '2-digit');
                                typeAttributes.put('hour', '2-digit');
                                typeAttributes.put('minute', '2-digit');  }  
        }
        return typeAttributes;
    }


    public static void testRelatedField(){
        // CustomOpportunity__c&c__col=Source__c%2CCreatedBy.Name%2CName%2CTAG_Is_my_NAV_region__c%2CTAG_IA_Service_End__c%2CCreateddate&c__id=001QI00000Zb8nHYAR&c__rf=Account__c&c__fv=Createddate>%3DTODAY
        String objectApiName = 'CustomOpportunity__c';
        String columns = 'Name, CreatedBy.Name';
        String relationshipField = 'Account__c';
        String parentRecordId = '001QI00000Zb8nHYAR';
        String filter = null;
        List<SObject> records = getRecordData(objectApiName, columns, relationshipField, parentRecordId, filter);
        System.debug('Record: '+records);
        List<Record> recordsWithFields = createListOfRecords(records, objectApiName, columns);
        System.debug('recordsWithFields: '+recordsWithFields);
    }

} 