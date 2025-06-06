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
        String sistEndretTekst = model.sist_endret;
        mottaker = model.mottaker;
        kontonr = model.kontonr;
        sist_endret = left(sistEndretTekst, 19);
        feilmelding = model.feilmelding;
    }
}
