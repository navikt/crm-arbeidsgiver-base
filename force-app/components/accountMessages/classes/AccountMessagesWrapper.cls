public with sharing class AccountMessagesWrapper {
    @AuraEnabled
    public String accountId { get; set; }
    @AuraEnabled
    public String field { get; set; }

    public AccountMessagesWrapper(String accountId, String field) {
        this.accountId = accountId;
        this.field = field;
    }
}