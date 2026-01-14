public with sharing class ListViewController {
    // select id, DeveloperName, LastReferencedDate, LastViewedDate  from ListView  where SobjectType ='TAG_Announcement__c'
    // Get LastViewedDate for ListView
    // Takes list view name as input and returns last viewed av datetime value
    @AuraEnabled(cacheable=true)
    public static DateTime getListViewLastViewedDate(String listViewName) {
        DateTime lastViewedDate;
        try {
            ListView lv = [
                SELECT LastViewedDate
                FROM ListView
                WHERE DeveloperName = :listViewName
                LIMIT 1
            ];
            lastViewedDate = lv.LastViewedDate;
        } catch (Exception e) {
            // Handle exception (e.g., log error)
            lastViewedDate = null;
        }
        return lastViewedDate;
    }
}