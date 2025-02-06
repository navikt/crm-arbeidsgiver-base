public with sharing class AccountMessagesWrapper {
    @AuraEnabled
    public String accountId { get; set; } // relatedAccount when bankrupt or forced settlement
    @AuraEnabled
    public String field { get; set; } // message when bankrupt or forced settlement
    @AuraEnabled
    public String deletedMessage { get; set; } // date when deleted in ereg

    public AccountMessagesWrapper() {
    }

    public AccountMessagesWrapper(String accountId, String field) {
        this.accountId = accountId;
        this.field = field;
    }
}
