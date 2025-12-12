public with sharing class BadgeController {
    private static Map<String, Map<String, String>> badgeConfig = new Map<String, Map<String, String>>();
    private static final LoggerUtility LOGGER = new LoggerUtility();

    @AuraEnabled(cacheable=true)
    public static List<BadgeService.Badge> createBadgesWithRelatedRecords(Id recordId, String keys) {
        // Create badges using existing method
        List<BadgeService.Badge> badges = createBadges(recordId, keys);
        // Get related records using existing method
        for (BadgeService.Badge badge : badges) {
            List<BadgeService.RecordWrapper> relatedRecords = getRecords(recordId, badge.badgeKey);
            badge.relatedRecords = relatedRecords;
            badge.recordCount = relatedRecords.size();
        }
        return badges;
    }

    /**
     * @description Creates badges for a given record based on its fields and related records.
     * @param recordId The Id of the record for which to create badges.
     * @param keys String of keys from BadgeConfigProvider.
     * @return A list of badges created for the record.
     */
    @AuraEnabled(cacheable=true)
    public static List<BadgeService.Badge> createBadges(Id recordId, String keys) {
        List<BadgeService.Badge> badges = new List<BadgeService.Badge>();
        if (recordId == null || String.isEmpty(keys)) {
            return new List<BadgeService.Badge>();
        }

        try {
            List<String> badgeKeys = keys.split(',');

            for (String badgeKey : badgeKeys) {
                badgeConfig.put(badgeKey.trim(), BadgeConfigProvider.getBadgeConfig(badgeKey.trim()));
            }

            for (String badgeKey : badgeConfig.keySet()) {
                Map<String, String> config = badgeConfig.get(badgeKey);
                Integer recordCount = BadgeService.getRecordCount(recordId, config);
                if (recordCount > 0) {
                    BadgeService.Badge badge = BadgeService.createBadgeFromConfig(
                        config,
                        new List<Object>{ recordCount },
                        new List<Object>{ recordId, badgeKey }
                    );
                    badges.add(badge);
                }
            }
        } catch (Exception e) {
            logError(recordId, e);
            return new List<BadgeService.Badge>();
        }

        return badges;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSettings(String badgeKey) {
        try {
            return BadgeConfigProvider.getBadgeConfig(badgeKey);
        } catch (Exception e) {
            logError(badgeKey, e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<BadgeService.RecordWrapper> getRecords(String recordId, String badgeKey) {
        try {
            Map<String, String> config = BadgeConfigProvider.getBadgeConfig(badgeKey);
            List<SObject> records = BadgeService.getRecords(recordId, config);
            List<BadgeService.RecordWrapper> recordsWithFields = BadgeService.convertToWrappedRecords(records, config);
            return recordsWithFields;
        } catch (Exception e) {
            logError(badgeKey, e);
            return null;
        }
    }
    /**
     * @description Logs an error for a given account.
     * @param referenceInfo The reference for which to log the error, for instance record Id or badge key.
     * @param e The exception to log.
     */
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