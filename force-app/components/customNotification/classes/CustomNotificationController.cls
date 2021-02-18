public with sharing class CustomNotificationController {
    @AuraEnabled(cacheable=true)
    public static String getFieldValue(String recordId, String field) {
        String sObjectType = getSOjectTypeFromRecordId(recordId);

        return getValue(recordId, sObjectType, field);
    }

    public static String getValue(String recordId, String sObjectType, String field) {
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(sObjectType);
        SObject so = convertType.newSObject();

        if (hasSObjectField(field, so)) {
            String query = 'SELECT ' + field + ' FROM ' + sObjectType + ' WHERE Id = \'' + recordId + '\'' + ' LIMIT 1';
            System.debug(
                '(String) Database.query( query )[0].get( field );: ' + (String) Database.query(query)[0].get(field)
            );

            return (String) Database.query(query)[0].get(field);
        }

        return null;
    }

    public static String getSOjectTypeFromRecordId(String recordId) {
        Id i = (Id) recordId;

        return String.valueOf(i.getSobjectType());
    }

    public static boolean hasSObjectField(String fieldName, SObject so) {
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
    }
}
