public with sharing class TAG_RecentItemsListController {
    @AuraEnabled(cacheable=true)
    public static List<VisitedWrapper> getRecentItems(
        Integer limitSize,
        String allowedObjects,
        String titleFieldsMapping,
        String secondaryFieldsMapping
    ) {
        // Default limit to 10 if null/invalid
        if (limitSize == null || limitSize <= 0) {
            limitSize = 10;
        }

        Set<String> allowedTypes = new Set<String>();
        if (String.isNotBlank(allowedObjects)) {
            for (String objName : allowedObjects.split(',')) {
                objName = objName.trim();
                if (objName != '') {
                    allowedTypes.add(objName);
                }
            }
        }

        // Parse titleFieldsMapping into a Map<String,String>
        Map<String,String> titleFieldMap = new Map<String,String>();
        if (String.isNotBlank(titleFieldsMapping)) {
            for (String entry : titleFieldsMapping.split(';')) {
                entry = entry.trim();
                if (entry.contains(':')) {
                    List<String> parts = entry.split(':');
                    String objName   = parts[0].trim();
                    String fieldName = parts[1].trim();
                    if (objName != '' && fieldName != '') {
                        titleFieldMap.put(objName, fieldName);
                    }
                }
            }
        }

        Map<String,String> secondaryFieldMap = new Map<String,String>();
        if (String.isNotBlank(secondaryFieldsMapping)) {
            for (String entry : secondaryFieldsMapping.split(';')) {
                entry = entry.trim();
                if (entry.contains(':')) {
                    List<String> parts = entry.split(':');
                    String objName   = parts[0].trim();
                    String fieldName = parts[1].trim();
                    if (objName != '' && fieldName != '') {
                        secondaryFieldMap.put(objName, fieldName);
                    }
                }
            }
        }

        // Query RecentlyViewed
        String rvSoql =
            'SELECT Id, Name, Type, LastViewedDate ' +
            'FROM RecentlyViewed ' +
            'WHERE Type != \'ListView\' ' +
            'AND Type != \'Dashboard\'';
        if (!allowedTypes.isEmpty()) {
            List<String> quoted = new List<String>();
            for (String t : allowedTypes) {
                quoted.add('\'' + String.escapeSingleQuotes(t) + '\'');
            }
            rvSoql += ' AND Type IN (' + String.join(quoted, ',') + ')';
        }
        rvSoql += ' ORDER BY LastViewedDate DESC LIMIT :limitSize';

        List<RecentlyViewed> recents = Database.query(rvSoql);
        if (recents.isEmpty()) {
            return new List<VisitedWrapper>();
        }

        // Group record IDs by sObject Type
        Map<String,List<Id>> typeToIds = new Map<String,List<Id>>();
        for (RecentlyViewed rv : recents) {
            String sType = rv.Type;
            if (!typeToIds.containsKey(sType)) {
                typeToIds.put(sType, new List<Id>());
            }
            typeToIds.get(sType).add(rv.Id);
        }

        // For each sObject Type, query display field (Name or override)
        Map<Id,String> idToTitle     = new Map<Id,String>();
        Map<Id,String> idToSecondary = new Map<Id,String>();
        for (String sType : typeToIds.keySet()) {
            List<Id> ids = typeToIds.get(sType);
            String primaryField   = titleFieldMap.containsKey(sType)     ? titleFieldMap.get(sType)     : 'Name';
            String secondaryField = secondaryFieldMap.containsKey(sType) ? secondaryFieldMap.get(sType) : null;

            String selectList = 'Id, ' + primaryField;
            if (secondaryField != null) {
                selectList += ', ' + secondaryField;
            }

            String dynSoql =
                'SELECT ' + selectList +
                ' FROM ' + sType +
                ' WHERE Id IN :ids';
                for (SObject sobj : Database.query(dynSoql)) {
                    Id rid = (Id) sobj.get('Id');
                
                    String titleValue = '';
                    if (primaryField.contains('.')) {
                        // split "Account__r.Name" → ["Account__r","Name"]
                        List<String> parts = primaryField.split('\\.');
                        String relName   = parts[0];
                        String fieldName = parts[1];
                        SObject parent = sobj.getSObject(relName);
                        if (parent != null) {
                            Object p = parent.get(fieldName);
                            titleValue = (p == null) ? '' : String.valueOf(p);
                        }
                    } else {
                        Object p = sobj.get(primaryField);
                        titleValue = (p == null) ? '' : String.valueOf(p);
                    }
                    idToTitle.put(rid, titleValue);
                
                    if (secondaryField != null) {
                        String secondaryValue = '';
                        if (secondaryField.contains('.')) {
                            List<String> parts2 = secondaryField.split('\\.');
                            SObject parent2 = sobj.getSObject(parts2[0]);
                            if (parent2 != null) {
                                Object s = parent2.get(parts2[1]);
                                secondaryValue = (s == null) ? '' : String.valueOf(s);
                            }
                        } else {
                            Object s = sobj.get(secondaryField);
                            secondaryValue = (s == null) ? '' : String.valueOf(s);
                        }
                        idToSecondary.put(rid, secondaryValue);
                    }
                }
        }
                
        List<String> distinctTypes = new List<String>(typeToIds.keySet());

        Map<String, String> typeToIconName = TAG_RecentItemsListHelper.getTypeToIconName(new Set<String>(distinctTypes));
       
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Map<String, String> typeToLabel = new Map<String, String>();
        for (String sType : typeToIds.keySet()) {
            if (gd.containsKey(sType)) {
                typeToLabel.put(sType, gd.get(sType).getDescribe().getLabel());
            } else {
                typeToLabel.put(sType, sType);
            }
        }

        List<VisitedWrapper> wrappers = new List<VisitedWrapper>();
        for (RecentlyViewed rv : recents) {
            VisitedWrapper w = new VisitedWrapper();
            w.recordId       = rv.Id;
            w.displayTitle   = idToTitle.containsKey(rv.Id) 
                                 ? idToTitle.get(rv.Id) 
                                 : rv.Name;
            w.secondaryOverride = idToSecondary.get(rv.Id);
            w.objectLabel       = typeToLabel.get(rv.Type); 
            w.sobjectType    = rv.Type;
            w.lastViewedDate = rv.LastViewedDate;
            w.url            = '/' + rv.Id;
            w.iconName       = typeToIconName.get(rv.Type);
            wrappers.add(w);
        }
        return wrappers;
    }

    public class VisitedWrapper {
        @AuraEnabled public Id     recordId;
        @AuraEnabled public String displayTitle;
        @AuraEnabled public String secondaryOverride;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String sobjectType;
        @AuraEnabled public Datetime lastViewedDate;
        @AuraEnabled public String url;
        @AuraEnabled public String iconName;  // e.g. "custom:custom71" or "standard:account"
    }
}