public with sharing class BankAccountModel {
    @AuraEnabled
    public String mottaker { get; set; }
    @AuraEnabled
    public String kontonr { get; set; }
    @AuraEnabled
    public String sist_endret { get; set; }
    @AuraEnabled
    public String feilmelding { get; set; }
    @AuraEnabled
    public Boolean isSuccess { get; set; }

    public void parse(String json) {
        BankAccountModel model = (BankAccountModel) System.JSON.deserialize(json, BankAccountModel.class);
        mottaker = model.mottaker;
        kontonr = model.kontonr;
        sist_endret = model.sist_endret;
        feilmelding = model.feilmelding;
    }
}
