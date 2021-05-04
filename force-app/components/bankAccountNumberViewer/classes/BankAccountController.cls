public with sharing class BankAccountController {
    @AuraEnabled(cacheable=true)
    public static String getBankAccountNumber(Id recordId) {
        return '1000101000';
    }
}
