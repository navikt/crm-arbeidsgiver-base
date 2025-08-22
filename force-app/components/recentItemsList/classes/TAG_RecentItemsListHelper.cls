public without sharing class TAG_RecentItemsListHelper {
    public static Map<String, String> getTypeToIconName(Set<String> distinctTypes) {
        Map<String, String> typeToIconName = new Map<String, String>();
        
        if (distinctTypes == null || distinctTypes.isEmpty()) {
            return typeToIconName;
        }

        // Initialize with nulls
        for (String sType : distinctTypes) {
            typeToIconName.put(sType, null);
        }

        // Query TabDefinition without sharing
        List<TabDefinition> tabs = [
            SELECT SobjectName,
                   (SELECT Url, ContentType FROM Icons)
            FROM TabDefinition
            WHERE SobjectName IN :distinctTypes
        ];

        // Map sObject → icons
        Map<String, List<IconDefinition>> iconsByType = new Map<String, List<IconDefinition>>();
        for (TabDefinition td : tabs) {
            iconsByType.put(td.SobjectName, td.Icons);
        }

        // Pick best icon for each sObject
        for (String sType : distinctTypes) {
            String chosenIconName = null;
            List<IconDefinition> iconDefs = iconsByType.get(sType);

            if (iconDefs != null && !iconDefs.isEmpty()) {
                // Pass 1: custom SVG
                for (IconDefinition idDef : iconDefs) {
                    if (idDef.ContentType != null 
                        && idDef.ContentType.contains('svg') 
                        && idDef.Url != null 
                        && idDef.Url.toLowerCase().contains('/custom/')) {
                        
                        chosenIconName = extractIconName(idDef.Url);
                        break;
                    }
                }
                // Pass 2: any SVG
                if (chosenIconName == null) {
                    for (IconDefinition idDef : iconDefs) {
                        if (idDef.ContentType != null 
                            && idDef.ContentType.contains('svg') 
                            && idDef.Url != null) {
                            
                            chosenIconName = extractIconName(idDef.Url);
                            break;
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

        return typeToIconName;
    }

    // utility to parse "/img/icon/t4v35/custom/custom71_120.svg" → "custom:custom71"
    private static String extractIconName(String url) {
        List<String> parts = url.split('/');
        if (parts.size() >= 2) {
            String folder = parts[parts.size() - 2];
            String filename = parts[parts.size() - 1].replace('.svg', '');
            if (folder == 'custom' && filename.contains('_')) {
                filename = filename.substring(0, filename.indexOf('_'));
            } else if (folder == 'standard' && filename.endsWith('_120')) {
                filename = filename.substring(0, filename.lastIndexOf('_120'));
            }
            return folder + ':' + filename;
        }
        return null;
    }
}