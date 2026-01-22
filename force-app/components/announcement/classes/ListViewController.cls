public with sharing class ListViewController {
    private static final LoggerUtility LOGGER = new LoggerUtility();
    // Get LastViewedDate for ListView
    // Takes list view name as input and returns last viewed av datetime value
    @AuraEnabled(cacheable=true)
    public static LastViewedDateResponse getListViewLastViewedDate(String listViewName, String sObjectType) {
        ListView lv = getListViewByName(listViewName, sObjectType);
        if (lv == null) {
            throw new AuraHandledException('ListView not found: ' + listViewName);
        }
        return new LastViewedDateResponse(true, lv.LastViewedDate);
    }

    private static ListView getListViewByName(String listViewName, String sObjectType) {
        try {
            ListView lv = [
                SELECT LastViewedDate
                FROM ListView
                WHERE DeveloperName = :listViewName AND SobjectType = :sObjectType
                LIMIT 1
            ];
            return lv;
        } catch (Exception e) {
            LOGGER.logMessage(
                LoggerUtility.LogLevel.Warning,
                '',
                listViewName + ' for sObjectType ' + sObjectType,
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

    public class LastViewedDateResponse {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public DateTime lastViewedDate;
        public LastViewedDateResponse(Boolean isSuccess, DateTime lastViewedDate) {
            this.isSuccess = isSuccess;
            this.lastViewedDate = lastViewedDate;
        }
    }
    /* --- IGNORE ---
         // Mock responses for testing purposes
        if (listViewName == 'mockError') {
            throw new AuraHandledException('Simulated error for testing purposes.');
        }
        if (listViewName == 'mockViewedDateNull') {
            return new LastViewedDateResponse(true, null);
        }
        if (listViewName == 'mockViewedDate') {
            return new LastViewedDateResponse(true, DateTime.newInstance(2000, 6, 1, 0, 0, 0));
        }
    */
}
