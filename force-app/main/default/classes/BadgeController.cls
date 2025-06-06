public with sharing class BadgeController {
    private static Map<String, Map<String, String>> badgeConfig = new Map<String, Map<String, String>>();
    private static final LoggerUtility LOGGER = new LoggerUtility();

    /**
     * @description Creates badges for a given record based on its fields and related records.
     * @param recordId The Id of the record for which to create badges.
     * @param keys String of keys from BadgeConfigProvider.
     * @return A list of badges created for the record.
     */
    @AuraEnabled(cacheable=true)
    public static List<BadgeService.Badge> createBadges(Id recordId, String keys) {
        system.debug(keys);
        List<BadgeService.Badge> badges = new List<BadgeService.Badge>();
        if (recordId == null || String.isEmpty(keys)) {
            system.debug('Missing input params');
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
                    system.debug(badge);
                }
            }
        } catch (Exception e) {
            logError(recordId, e);
            system.debug(e);
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
    public static List<BadgeService.Record> getRecords(String recordId, String badgeKey) {
        try {
            System.debug('badgeKey: ' + badgeKey);
            Map<String, String> config = BadgeConfigProvider.getBadgeConfig(badgeKey);
            List<SObject> records = BadgeService.getRecords(recordId, config);

            System.debug('Record: ' + records);
            List<BadgeService.Record> recordsWithFields = BadgeService.createListOfRecords(records, config);
            return recordsWithFields;
        } catch (Exception e) {
            logError(badgeKey, e);
            return null;
        }
    }
    /**
     * @description Logs an error for a given account.
     * @param recordId The Id of the Account for which to log the error.
     * @param e The exception to log.
     */
    private static void logError(Id recordId, Exception e) {
        LOGGER.logMessage(
            LoggerUtility.LogLevel.Error,
            '',
            recordId,
            e.getMessage(),
            e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.POAB
        );
        LOGGER.publish();
    }
}
