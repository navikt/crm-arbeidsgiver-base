public with sharing class BadgeService {
    private static Map<String, Map<String, String>> fieldLabelsByLang = new Map<String, Map<String, String>>{
        'OWNER' => new Map<String, String>{ 'NO_NB' => 'Eier', 'EN_US' => 'Owner' }
    };
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

    public static List<RecordWrapper> convertToWrappedRecords(List<SObject> records, Map<String, String> config) {
        String objectApiName = config.get('objectApiName');
        List<String> columns = config.get('columns').split(',');

        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new List<String>{ objectApiName });
        Map<String, Schema.SObjectField> fieldData = descResult[0].fields.getMap();

        List<RecordWrapper> recordList = new List<RecordWrapper>();
        for (SObject record : records) {
            recordList.add(createRecordWrapperFromSObject(record, columns, fieldData, config));
        }
        return recordList;
    }

    private static RecordWrapper createRecordWrapperFromSObject(
        SObject record,
        List<String> columns,
        Map<String, Schema.SObjectField> fieldData,
        Map<String, String> config
    ) {
        RecordWrapper rec = new RecordWrapper();
        String nameField = config.get('columns').split(',')[0].trim();

        String name = (String) record.get(nameField);
        // Strip HTML tags if present.
        if (!String.isBlank(name) && name.containsIgnoreCase('<a')) {
            name = name.replaceAll('<[^>]+>', '');
        }
        rec.name = name;

        rec.id = (String) record.get('Id');
        rec.link = createUrl(record);
        rec.icon = config.get('icon');
        // Create record.fields
        rec.fields = new List<Field>();
        for (String fieldName : columns) {
            rec.fields.add(createFieldFromSObject(record, fieldName.trim(), fieldData));
        }
        return rec;
    }

    /* Creates a Field object with value, label and type based on provided field name, record and field metadata form Schema.describeSObjects.
    Logic:
    - If TYPEOF Owner is used in query, returned records will have different fields based on the type of owner.
        - resolvePolymorphicOwnerField() replaces "TYPEOF Owner WHEN objectType THEN field.." with "Owner.field".
    - If fieldName is in fieldData, it is a field on the same object.
    - If fieldName contains a dot (.), it is a reference field in a lookup relation, e.g. Account__r.Name, Owner.Alias.
        - If object part of field name exists in fieldLabelsByLang then the label is unavailable through describe info and is instead fetched from fieldLabelsByLang.
         Currently just the Owner field.
        - If fieldName starts with __r, it is a custom field. Replace __r to __c and get metadata fieldData.
    */
    @TestVisible
    private static Field createFieldFromSObject(
        SObject record,
        String fieldName,
        Map<String, Schema.SObjectField> fieldData
    ) {
        Field field = new Field();
        Schema.DescribeFieldResult fieldDescribe;
        String objectPart;
        String fieldPart;
        SObject lookupRecord;
        if (fieldName.containsIgnoreCase('TYPEOF Owner')) {
            String typeOfField = record.getSObject('Owner').getSObjectType().toString(); // e.g. User or Group
            fieldName = resolvePolymorphicOwnerField(fieldName, typeOfField);
        }
        if (fieldData.containsKey(fieldName)) {
            // Fields on the same object
            fieldDescribe = fieldData.get(fieldName).getDescribe();
            field.label = fieldDescribe.getLabel();
            field.fieldName = fieldName;
            field.type = mapFieldType(fieldDescribe);
            field.typeAttributes = createTypeAttributes(fieldDescribe.getType());
            field.value = getFieldDisplayValue(record, fieldName, fieldDescribe); // Use display value for picklists
        } else if (fieldName.contains('.')) {
            List<String> relatedField = fieldName.split('\\.');
            objectPart = relatedField[0];
            fieldPart = relatedField[1];
            lookupRecord = record.getSObject(objectPart);

            if (fieldLabelsByLang.containsKey(objectPart.toUpperCase())) {
                // Handle field labels for Owner and other standard reference fields.
                fieldDescribe = lookupRecord.getSObjectType()
                    .getDescribe()
                    .fields.getMap()
                    .get(fieldPart)
                    .getDescribe();
                String relationLabel = fieldLabelsByLang.get(objectPart.toUpperCase())
                    .get(UserInfo.getLanguage().toUpperCase());
                String label = relationLabel + ' ' + fieldDescribe.getLabel().toLowerCase();
                field.label = label;
                field.fieldName = objectPart + '_' + fieldPart;
                field.type = 'text';
                field.value = lookupRecord.get(fieldPart);
            } else {
                if (fieldName.split('\\.')[0]?.contains('__r')) {
                    fieldDescribe = fieldData.get(objectPart.replace('__r', '__c')).getDescribe();
                } else {
                    fieldDescribe = lookupRecord.getSObjectType()
                        .getDescribe()
                        .fields.getMap()
                        .get(fieldPart)
                        .getDescribe();
                }
                field = createReferenceField(lookupRecord, fieldDescribe, objectPart, fieldPart);
            }
        }

        return field;
    }

    private static String createUrl(SObject record) {
        return '/lightning/r/' + record.getSObjectType().toString() + '/' + record.get('Id') + '/view';
    }

    /* Create field with custom datatype to display lookup field as link.
    Sets the "value" of a field to a Record object and type as c_reference. When LWC iterates fields, it will render as a link.    
    */
    private static Field createReferenceField(
        sObject lookupRecord,
        Schema.DescribeFieldResult fieldDescribe,
        String objectPart,
        String fieldPart
    ) {
        RecordWrapper recordWrapper = new RecordWrapper();
        recordWrapper.name = (String) lookupRecord.get(fieldPart);
        recordWrapper.id = (String) lookupRecord.get('Id');
        recordWrapper.link = createUrl(lookupRecord);
        Field lookupField = new Field();
        lookupField.label = fieldDescribe.getLabel();
        lookupField.fieldName = objectPart + '_' + fieldPart;
        lookupField.type = 'c_reference';
        lookupField.value = recordWrapper;
        return lookupField;
    }

    @TestVisible
    private static String resolvePolymorphicOwnerField(String column, String whenObjectType) {
        // https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_typeof.htm
        // TYPEOF typeOfField WHEN whenObjectType THEN whenFieldList END >> typeOfField.whenFieldList[n]..
        // Only supports one field type per WHEN clause.
        String typeOfField;
        column = column.remove(' END');
        String[] whenParts = column.split('WHEN');
        for (String part : whenParts) {
            if (part.trim().startsWithIgnoreCase('TYPEOF ')) {
                typeOfField = part.remove('TYPEOF ').trim();
            } else if (part.trim().startsWithIgnoreCase(whenObjectType.trim() + ' THEN ')) {
                String[] thenParts = part.split(' THEN ');
                String whenFieldList = thenParts[1].trim();
                return typeOfField + '.' + whenFieldList; // e.g. Owner.Alias
            }
        }
        return null;
    }

    private static Object getFieldDisplayValue(
        SObject record,
        String fieldName,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        // Return the picklist label if the field is a picklist, otherwise return the raw value
        Object value = record.get(fieldName);
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist && value != null) {
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.getValue() == (String) value) {
                    return entry.getLabel();
                }
            }
            // Fallback to API value if label not found
            return value;
        }
        return value;
    }

    // Types are matched in the template.
    // ToDo: Should be converted to static final variables
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

    public class RecordWrapper {
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
