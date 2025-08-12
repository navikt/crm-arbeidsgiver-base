/*public with sharing class TAG_RecentActionsListController {

    @AuraEnabled(cacheable=true)
    public static List<VisitedWrapper> getRecentActions(
        Integer limitSize,
        String allowedObjects,
        String titleFieldsMapping,
        String secondaryFieldsMapping
    ) {
        limitSize = (limitSize == null || limitSize <= 0) ? 10 : limitSize;
        Id currentUserId = UserInfo.getUserId();

        Set<String> allowedTypes = parseAllowedObjects(allowedObjects);
        Map<String, String> titleFieldMap = parseFieldMapping(titleFieldsMapping);
        Map<String, String> secondaryFieldMap = parseFieldMapping(secondaryFieldsMapping);

        List<VisitedWrapper> allWrappers = new List<VisitedWrapper>();

        for (String sType : allowedTypes) {
            //String primaryField = titleFieldMap.getOrDefault(sType, 'Name');
            String secondaryField = secondaryFieldMap.get(sType);
            String selectFields = buildSelectFields(primaryField, secondaryField);

            String query = 'SELECT ' + selectFields +
                           ' FROM ' + sType +
                           ' WHERE LastModifiedById = :currentUserId OR CreatedById = :currentUserId' +
                           ' ORDER BY LastModifiedDate DESC LIMIT :limitSize';

            try {
                List<SObject> records = Database.query(query);
                allWrappers.addAll(buildWrappers(records, sType, primaryField, secondaryField));
            } catch (Exception e) {
                System.debug('Error querying object ' + sType + ': ' + e.getMessage());
            }
        }

        // Sort all wrappers by LastModifiedDate descending
        //allWrappers.sort((a, b) => b.lastViewedDate.compareTo(a.lastViewedDate));

        // Return only the top `limitSize` records.
        return allWrappers.size() > limitSize ? allWrappers.subList(0, limitSize) : allWrappers;
    }

    private static Set<String> parseAllowedObjects(String allowedObjects) {
        Set<String> allowedTypes = new Set<String>();
        if (String.isNotBlank(allowedObjects)) {
            for (String objName : allowedObjects.split(',')) {
                objName = objName.trim();
                if (!objName.isEmpty()) {
                    allowedTypes.add(objName);
                }
            }
        }
        return allowedTypes;
    }

    private static Map<String, String> parseFieldMapping(String mapping) {
        Map<String, String> result = new Map<String, String>();
        if (String.isNotBlank(mapping)) {
            for (String entry : mapping.split(';')) {
                List<String> parts = entry.split(':');
                if (parts.size() == 2) {
                    result.put(parts[0].trim(), parts[1].trim());
                }
            }
        }
        return result;
    }

    private static String buildSelectFields(String primaryField, String secondaryField) {
        String selectFields = 'Id, ' + primaryField + ', LastModifiedDate';
        if (secondaryField != null) {
            selectFields += ', ' + secondaryField;
        }
        return selectFields;
    }

    private static List<VisitedWrapper> buildWrappers(List<SObject> records, String sType, String primaryField, String secondaryField) {
        List<VisitedWrapper> wrappers = new List<VisitedWrapper>();
        for (SObject sobj : records) {
            VisitedWrapper w = new VisitedWrapper();
            w.recordId = (Id)sobj.get('Id');
            w.displayTitle = String.valueOf(sobj.get(primaryField));
            w.secondaryOverride = secondaryField != null ? String.valueOf(sobj.get(secondaryField)) : null;
            w.objectLabel = sType;
            w.sobjectType = sType;
            w.lastViewedDate = (Datetime)sobj.get('LastModifiedDate');
            w.url = '/' + sobj.get('Id');
            w.iconName = sType.endsWith('__c') ? 'standard:custom' : 'standard:record';
            wrappers.add(w);
        }
        return wrappers;
    }

    public class VisitedWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String displayTitle;
        @AuraEnabled public String secondaryOverride;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String sobjectType;
        @AuraEnabled public Datetime lastViewedDate;
        @AuraEnabled public String url;
        @AuraEnabled public String iconName;
    }
}*/


public with sharing class TAG_RecentActionsListController {
    @AuraEnabled(cacheable=true)
    public static List<VisitedWrapper> getRecentActions(
        Integer limitSize,
        String allowedObjects,
        String titleFieldsMapping,
        String secondaryFieldsMapping
    ) {
        if (limitSize == null || limitSize <= 0) {
            limitSize = 10;
        }

        Id currentUserId = UserInfo.getUserId();

        Set<String> allowedTypes = new Set<String>();
        if (String.isNotBlank(allowedObjects)) {
            for (String objName : allowedObjects.split(',')) {
                objName = objName.trim();
                if (objName != '') {
                    allowedTypes.add(objName);
                }
            }
        }
        
        Map<String,String> titleFieldMap = parseFieldMapping(titleFieldsMapping);
        Map<String,String> secondaryFieldMap = parseFieldMapping(secondaryFieldsMapping);

        List<VisitedWrapper> wrappers = new List<VisitedWrapper>();

        for (String sType : allowedTypes) {
            String primaryField = titleFieldMap.get(sType) != null ? titleFieldMap.get(sType) : 'Name';
            String secondaryField = secondaryFieldMap.get(sType);

            String selectFields = 'Id, ' + primaryField + ', LastModifiedDate';
            if (secondaryField != null) {
                selectFields += ', ' + secondaryField;
            }

            String query = 'SELECT ' + selectFields +
                           ' FROM ' + sType +
                           ' WHERE LastModifiedById = :currentUserId OR CreatedById = :currentUserId ' +
                           ' ORDER BY LastModifiedDate DESC LIMIT :limitSize';

            try {
                List<SObject> records = Database.query(query);
                for (SObject sobj : records) {
                    VisitedWrapper w = new VisitedWrapper();
                    w.recordId = (Id)sobj.get('Id');
                    w.displayTitle = String.valueOf(sobj.get(primaryField));
                    w.secondaryOverride = secondaryField != null ? String.valueOf(sobj.get(secondaryField)) : null;
                    w.objectLabel = sType;
                    w.sobjectType = sType;
                    w.lastViewedDate = (Datetime)sobj.get('LastModifiedDate');
                    w.url = '/' + sobj.get('Id');
                    w.iconName = sType.endsWith('__c') ? 'standard:custom' : 'standard:record';
                    wrappers.add(w);
                }
            } catch (Exception e) {
                System.debug('Error querying object ' + sType + ': ' + e.getMessage());
            }
        }

        return wrappers;
    }

    private static Map<String,String> parseFieldMapping(String mapping) {
        Map<String,String> result = new Map<String,String>();
        if (String.isNotBlank(mapping)) {
            for (String entry : mapping.split(';')) {
                List<String> parts = entry.split(':');
                if (parts.size() == 2) {
                    result.put(parts[0].trim(), parts[1].trim());
                }
            }
        }
        return result;
    }

    public class VisitedWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String displayTitle;
        @AuraEnabled public String secondaryOverride;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String sobjectType;
        @AuraEnabled public Datetime lastViewedDate;
        @AuraEnabled public String url;
        @AuraEnabled public String iconName;
    }
}
