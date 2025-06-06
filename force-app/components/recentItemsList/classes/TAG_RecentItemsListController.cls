public with sharing class TAG_RecentItemsListController {
    @AuraEnabled(cacheable=true)
    public static List<VisitedWrapper> getRecentItems(
        Integer limitSize,
        String allowedObjects,
        String titleFieldsMapping
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

        // Query RecentlyViewed
        String rvSoql =
            'SELECT Id, Name, Type, LastViewedDate ' +
            'FROM RecentlyViewed';
        if (!allowedTypes.isEmpty()) {
            List<String> quoted = new List<String>();
            for (String t : allowedTypes) {
                quoted.add('\'' + String.escapeSingleQuotes(t) + '\'');
            }
            rvSoql += ' WHERE Type IN (' + String.join(quoted, ',') + ')';
        }
        rvSoql += ' ORDER BY LastViewedDate DESC LIMIT :limitSize';

        List<RecentlyViewed> recents = Database.query(rvSoql);
        if (recents.isEmpty()) {
            return new List<VisitedWrapper>();
        }

        // Group record IDs by sObject Type
        Map<String, List<Id>> typeToIds = new Map<String, List<Id>>();
        for (RecentlyViewed rv : recents) {
            String sType = rv.Type;
            if (!typeToIds.containsKey(sType)) {
                typeToIds.put(sType, new List<Id>());
            }
            typeToIds.get(sType).add(rv.Id);
        }

        // For each sObject Type, query display field (Name or override)
        Map<Id,String> idToTitle = new Map<Id,String>();
        for (String sType : typeToIds.keySet()) {
            List<Id> ids = typeToIds.get(sType);
            String fieldToSelect = 'Name';
            if (titleFieldMap.containsKey(sType)) {
                fieldToSelect = titleFieldMap.get(sType);
            }
            String dynSoql =
                'SELECT Id, ' + fieldToSelect +
                ' FROM ' + sType +
                ' WHERE Id IN :ids';
            for (SObject sobj : Database.query(dynSoql)) {
                Id rid = (Id) sobj.get('Id');
                Object val = sobj.get(fieldToSelect);
                idToTitle.put(rid, val == null ? '' : String.valueOf(val));
            }
        }

        List<String> distinctTypes = new List<String>(typeToIds.keySet());

        // Query TabDefinition and its Icons
        Map<String, String> typeToIconName = new Map<String, String>();
        if (!distinctTypes.isEmpty()) {
            List<TabDefinition> tabs = [
                SELECT SobjectName,
                       (SELECT Url, ContentType FROM Icons)
                FROM TabDefinition
                WHERE SobjectName IN :distinctTypes
            ];

            // Initialize with null
            for (String sType : distinctTypes) {
                typeToIconName.put(sType, null);
            }

            // Build a helper map: sObject → list of IconDefinition (Url + ContentType)
            Map<String, List<IconDefinition>> iconsByType = new Map<String, List<IconDefinition>>();
            for (TabDefinition td : tabs) {
                iconsByType.put(td.SobjectName, td.Icons);
            }

            // For each sObject type, pick a custom‐icon SVG first, else a standard SVG
            for (String sType : distinctTypes) {
                String chosenIconName = null;
                List<IconDefinition> iconDefs = iconsByType.get(sType);

                if (iconDefs != null && !iconDefs.isEmpty()) {
                    // 1st pass: find SVG containing "/custom/"
                    for (IconDefinition idDef : iconDefs) {
                        if (idDef.ContentType != null 
                            && idDef.ContentType.contains('svg') 
                            && idDef.Url != null 
                            && idDef.Url.toLowerCase().contains('/custom/')) {
                            // e.g. "/img/icon/t4v35/custom/custom71_120.svg"
                            String url = idDef.Url;
                            List<String> parts = url.split('/');
                            if (parts.size() >= 2) {
                                String folder = parts[parts.size()-2];       // "custom"
                                String filename = parts[parts.size()-1];     // e.g. "custom71_120.svg"
                                filename = filename.replace('.svg','');
                                // strip "_120" suffix if present
                                if (folder == 'custom' && filename.contains('_')) {
                                    filename = filename.substring(0, filename.indexOf('_'));
                                }
                                chosenIconName = folder + ':' + filename;     // "custom:custom71"
                                break;
                            }
                        }
                    }
                    // 2nd pass: if no custom SVG found, find any SVG
                    if (chosenIconName == null) {
                        for (IconDefinition idDef : iconDefs) {
                            if (idDef.ContentType != null 
                                && idDef.ContentType.contains('svg') 
                                && idDef.Url != null) {
                                String url = idDef.Url;
                                List<String> parts = url.split('/');
                                if (parts.size() >= 2) {
                                    String folder = parts[parts.size()-2];       // "standard" or "custom"
                                    String filename = parts[parts.size()-1];     // e.g. "account_120.svg"
                                    filename = filename.replace('.svg','');
                                    if (folder == 'standard' && filename.endsWith('_120')) {
                                        filename = filename.substring(0, filename.lastIndexOf('_120'));
                                    }
                                    chosenIconName = folder + ':' + filename;     // "standard:account"
                                    break;
                                }
                            }
                        }
                    }
                }

                if (chosenIconName == null) {
                    if (sType != null && sType.endsWith('__c')) {
                        chosenIconName = 'standard:custom';
                    } else {
                        chosenIconName = 'standard:record';
                    }
                }
                typeToIconName.put(sType, chosenIconName);
            }
        }

        List<VisitedWrapper> wrappers = new List<VisitedWrapper>();
        for (RecentlyViewed rv : recents) {
            VisitedWrapper w = new VisitedWrapper();
            w.recordId       = rv.Id;
            w.displayTitle   = idToTitle.containsKey(rv.Id) 
                                 ? idToTitle.get(rv.Id) 
                                 : rv.Name;
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
        @AuraEnabled public String sobjectType;
        @AuraEnabled public Datetime lastViewedDate;
        @AuraEnabled public String url;
        @AuraEnabled public String iconName;  // e.g. "custom:custom71" or "standard:account"
    }
}