public with sharing class TAG_RecentItemsListController {
    @AuraEnabled(cacheable=true)
    public static List<VisitedWrapper> getRecentItems(Integer limitSize) {
        // Default to 10 if passed in null or <= 0
        if (limitSize == null || limitSize <= 0) {
            limitSize = 10;
        }

        List<RecentlyViewed> recentList = [
            SELECT Id,
                   Name,
                   Type,
                   LastViewedDate
            FROM RecentlyViewed
            ORDER BY LastViewedDate DESC
            LIMIT :limitSize
        ];

        List<VisitedWrapper> wrapped = new List<VisitedWrapper>();
        for (RecentlyViewed rv : recentList) {
            VisitedWrapper vw = new VisitedWrapper();
            vw.recordId        = rv.Id;
            vw.name            = rv.Name;
            vw.sobjectType     = rv.Type;
            vw.lastViewedDate  = rv.LastViewedDate;
            wrapped.add(vw);
        }
        return wrapped;
    }

    public class VisitedWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String sobjectType;
        @AuraEnabled public Datetime lastViewedDate;
    }
}