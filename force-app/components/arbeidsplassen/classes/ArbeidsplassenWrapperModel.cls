public with sharing class ArbeidsplassenWrapperModel {
    @AuraEnabled
    public Integer amount { get; set; }
    @AuraEnabled
    public List<ArbeidsplassenViewModel> models { get; set; }

    public ArbeidsplassenWrapperModel(
        Integer amount,
        List<ArbeidsplassenViewModel> models
    ) {
        this.amount = amount;
        this.models = models;
    }
}
