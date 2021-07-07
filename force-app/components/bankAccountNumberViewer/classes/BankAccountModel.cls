public with sharing class BankAccountModel {
    @AuraEnabled
    public String mottaker { get; set; }
    @AuraEnabled
    public String kontonr { get; set; }
    @AuraEnabled
    public String feilmelding { get; set; }
    @AuraEnabled
    public Boolean isSuccess { get; set; }

    public BankAccountModel parse(String json) {
        return (BankAccountModel) System.JSON.deserialize(json, BankAccountModel.class);
    }
}
