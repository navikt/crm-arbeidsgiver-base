public with sharing class AccountSummaryController {
    private static final LoggerUtility LOGGER = new LoggerUtility();

    /**
     * @description Returns the full account summary (ongoing activity, history and written summary).
     * @param recordId Id of an Account or EmployerInquiry__c record.
     * @param months History period, 6 or 12. Other values default to 6.
     */
    @AuraEnabled(cacheable=true)
    public static AccountSummaryService.Summary getSummary(Id recordId, Integer months) {
        try {
            return AccountSummaryService.buildSummary(recordId, months);
        } catch (Exception e) {
            logError(String.valueOf(recordId), e);
            throw new AuraHandledException('Kunne ikke hente oversikt over arbeidsgiveren.');
        }
    }

    /**
     * @description Returns the records behind one row in "Pågående aktivitet".
     * @param recordId Id of an Account or EmployerInquiry__c record.
     * @param key Row key from AccountSummaryConfig.
     */
    @AuraEnabled(cacheable=true)
    public static List<BadgeService.RecordWrapper> getRecords(Id recordId, String key) {
        try {
            return AccountSummaryService.getRecords(recordId, key);
        } catch (Exception e) {
            logError(key, e);
            throw new AuraHandledException('Kunne ikke hente poster.');
        }
    }

    private static void logError(String referenceInfo, Exception e) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            referenceInfo,
            e.getMessage(),
            e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        LOGGER.publish();
    }
}
