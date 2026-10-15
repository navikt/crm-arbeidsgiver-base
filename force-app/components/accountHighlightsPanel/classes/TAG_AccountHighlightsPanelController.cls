public with sharing class TAG_AccountHighlightsPanelController {
    private static final Integer RELATED_ACCOUNTS_LIMIT = 10;

    @AuraEnabled(cacheable=true)
    public static String getEmployees(Id recordId) {
        List<Account> acc = [
            SELECT Id, INT_HasEmployees__c, NumberOfEmployees
            FROM Account
            WHERE Id = :recordId
        ];

        if (
            (acc[0].INT_HasEmployees__c == true && acc[0].NumberOfEmployees < 5) ||
            (acc[0].INT_HasEmployees__c == true &&
            acc[0].NumberOfEmployees == null)
        ) {
            return '1-4';
        } else if (acc[0].INT_HasEmployees__c == true && acc[0].NumberOfEmployees >= 5) {
            return String.valueOf(acc[0].NumberOfEmployees);
        } else {
            return '0';
        }
    }

    @AuraEnabled(cacheable=true)
    public static RelatedAccounts getRelatedAccounts(Id ultimateParentId) {
        RelatedAccounts result = new RelatedAccounts();
        if (ultimateParentId == null) {
            result.totalCount = 0;
            result.accounts = new List<Account>();
            return result;
        }
        // The ultimate parent references itself, so it is excluded explicitly.
        result.totalCount = [
            SELECT COUNT()
            FROM Account
            WHERE CRM_UltimateParentAccount__c = :ultimateParentId AND Id != :ultimateParentId
            WITH USER_MODE
        ];
        result.accounts = [
            SELECT
                Id,
                Name,
                CRM_AccountType__c,
                INT_OrganizationNumber__c,
                ShippingCity,
                CRM_NumberOfEmployeesGrouped__c
            FROM Account
            WHERE CRM_UltimateParentAccount__c = :ultimateParentId AND Id != :ultimateParentId
            WITH USER_MODE
            ORDER BY Name
            LIMIT :RELATED_ACCOUNTS_LIMIT
        ];
        return result;
    }

    public class RelatedAccounts {
        @AuraEnabled
        public Integer totalCount;
        @AuraEnabled
        public List<Account> accounts;
    }
}
