/**
 * Provides user office header data for the current user context.
 */
public with sharing class TAG_UserOfficeHeaderController {
    /**
     * Finds record Id for NavUnit__c by its name.
     *
     * @param companyName The name used to find the Nav unit.
     * @return The Nav unit record Id, or null when the name is blank, the user lacks access, or no match is found.
     */
    @AuraEnabled(cacheable=true)
    public static String getNavUnitIdByCompanyName(String companyName) {
        if (String.isBlank(companyName)) {
            return null;
        }
        if (!Schema.sObjectType.NavUnit__c.isAccessible()) {
            return null;
        }
        List<NavUnit__c> navUnits = [
            SELECT Id
            FROM NavUnit__c
            WHERE Name = :companyName
            LIMIT 1
        ];
        if (!navUnits.isEmpty()) {
            return navUnits[0].Id;
        } else {
            return null;
        }
    }
}
