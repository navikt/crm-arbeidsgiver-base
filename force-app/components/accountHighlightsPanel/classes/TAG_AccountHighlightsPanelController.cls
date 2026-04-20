public with sharing class TAG_AccountHighlightsPanelController {
    @AuraEnabled(cacheable=true)
    public static String getEmployees(Id recordId) {
        List<Account> acc = [
            SELECT
                Id,
                INT_HasEmployees__c,
                NumberOfEmployees
            FROM Account
            WHERE Id = :recordId
        ];

        if (acc[0].INT_HasEmployees__c == true && acc[0].NumberOfEmployees < 5) {
            return '1-4';      
        } else if (acc[0].INT_HasEmployees__c == true && acc[0].NumberOfEmployees >= 5) {
            return String.valueOf(acc[0].NumberOfEmployees);
        } else {
            return '0';
        }
    }
}
