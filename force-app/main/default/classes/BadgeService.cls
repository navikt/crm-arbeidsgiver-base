public with sharing class BadgeService {
    /**
     * @description Create a badge from config
     * @param key The key used for config in BADGE_CONFIG.
     * @param labelMergeFields List of values to use in labelTemplate. If template has no merge fields, this can be null.
     * @param urlMergeFields List of values to use in urlTemplate. If template has no merge fields, this can be null.
     * @return A new badge.
     */
    public static Badge createBadgeFromConfig(
        Map<String, String> config,
        List<Object> labelMergeFields,
        List<Object> urlMergeFields
    ) {
        String label = labelMergeFields != null
            ? String.format(config.get('labelTemplate'), labelMergeFields)
            : config.get('labelTemplate');
        String url = urlMergeFields != null
            ? String.format(config.get('urlTemplate'), urlMergeFields)
            : config.get('urlTemplate');
        return new Badge(
            label,
            url,
            config.get('helpText'),
            config.get('badgeType'),
            config.get('badgeKey'),
            config.get('icon')
        );
    }

    /**
     * @description Fetches records of a given object type for a specific account.
     * @param recordId The Id of the Account to fetch records for.
     * @param objectName The name of the object to fetch records from.
     * @return A list of records of the specified object type.
     */
    public static Integer getRecordCount(Id recordId, Map<String, String> config) {
        String objectApiName = config.get('objectApiName');
        String columns = 'COUNT()';
        String lookupField = config.get('lookupField');
        String filter = config.get('queryFilter');
        String query = 'SELECT ' + columns + ' FROM ' + objectApiName + ' WHERE ' + lookupField + ' = :recordId';
        if (String.isNotBlank(filter)) {
            query += ' AND ' + filter;
        }
        Integer queryResult;
        try {
            queryResult = Database.countQuery(query, AccessLevel.USER_MODE);
            return queryResult;
        } catch (QueryException e) {
            return null;
        }
    }

    public static List<SObject> getRecords(Id recordId, Map<String, String> config) {
        List<SObject> records;
        String objectApiName = config.get('objectApiName');
        String columns = config.get('columns');
        String lookupField = config.get('lookupField');
        String filter = config.get('queryFilter');
        String icon = config.get('icon');

        String query = 'SELECT ' + columns + ' FROM ' + objectApiName + ' WHERE ' + lookupField + ' = :recordId';
        if (String.isNotBlank(filter)) {
            query += ' AND ' + filter;
        }
        try {
            records = Database.query(query, AccessLevel.USER_MODE);
            return records;
        } catch (QueryException e) {
            return null;
        }
    }

    public static List<Record> createListOfRecords(List<SObject> records, Map<String, String> config) {
        String objectApiName = config.get('objectApiName');
        String icon = config.get('icon');
        List<String> columns = config.get('columns').replace(' ', '').split(',');
        Map<String, Schema.SObjectField> fieldData = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap();
        List<Record> recordList = new List<Record>();
        for (SObject record : records) {
            Record rec = new Record();
            rec.name = (String) record.get(columns[0]);
            rec.id = (String) record.get('Id');
            rec.link = '/' + rec.id;
            rec.icon = icon;
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
                } else {
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
        if (field.getType() == Schema.DisplayType.STRING && field.isHtmlFormatted()) {
            return 'customRichText';
        }
        Schema.DisplayType type = field.getType();
        switch on type {
            when Email {
                return 'email';
            }
            when Phone {
                return 'phone';
            }
            when Date {
                return 'date';
            }
            when DateTime {
                return 'date';
            }
            when Double {
                return 'number';
            }
            when Integer {
                return 'number';
            }
            when Boolean {
                return 'boolean';
            }
            when Picklist {
                return 'text';
            }
            when Address {
                return 'address';
            }
            when String {
                return 'text';
            }
            when else {
                return 'text';
            }
        }
    }

    private static Map<String, Object> createTypeAttributes(Schema.DisplayType type) {
        Map<String, Object> typeAttributes = new Map<String, Object>();
        switch on type {
            when String {
                typeAttributes.put('linkify', true);
            }
            when Datetime {
                typeAttributes.put('year', 'numeric');
                typeAttributes.put('month', '2-digit');
                typeAttributes.put('day', '2-digit');
                typeAttributes.put('hour', '2-digit');
                typeAttributes.put('minute', '2-digit');
            }
        }
        return typeAttributes;
    }

    /** Wrapper class for single badge */
    public class Badge {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String helpText;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public String badgeType;
        @AuraEnabled
        public String badgeKey;
        @AuraEnabled
        public String icon;

        public Badge(String label, String url, String helpText, String badgeType, String badgeKey, String icon) {
            this.label = label;
            this.helpText = helpText;
            this.url = url;
            this.badgeType = badgeType;
            this.badgeKey = badgeKey;
            this.icon = icon;
        }
    }

    public class Record {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String link;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public List<Field> fields; // Field metadata
    }
    public class Field {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Object value;
        @AuraEnabled
        public Map<String, Object> typeAttributes;
    }
}
