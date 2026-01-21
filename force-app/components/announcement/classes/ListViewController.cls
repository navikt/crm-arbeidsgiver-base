public with sharing class ListViewController {
    private static final LoggerUtility LOGGER = new LoggerUtility();

    // select id, DeveloperName, LastReferencedDate, LastViewedDate  from ListView  where SobjectType ='TAG_Announcement__c'
    // Get LastViewedDate for ListView
    // Takes list view name as input and returns last viewed av datetime value
    @AuraEnabled(cacheable=true)
    public static DateTime getListViewLastViewedDate(String listViewName) {
        ListView lv = getListViewByName(listViewName);
        if (lv == null) {
            throw new AuraHandledException('ListView not found: ' + listViewName);
        }
        return lv.LastViewedDate;
    }

    private static ListView getListViewByName(String listViewName) {
        try {
            ListView lv = [
                SELECT LastViewedDate
                FROM ListView
                WHERE DeveloperName = :listViewName
                LIMIT 1
            ];
            return lv;
        } catch (Exception e) {
            LOGGER.logMessage(
                LoggerUtility.LogLevel.Warning,
                '',
                listViewName,
                e.getMessage() +
                    ', meaning ListView ' +
                    listViewName +
                    ' was not found. Verify spelling and sharing settings.',
                e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.POAB
            );
            LOGGER.publish();
            return null;
        }
    }
}
