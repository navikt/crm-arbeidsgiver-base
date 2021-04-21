public without sharing class DeleteContactExtension {
    private final Contact cont;

    public deleteContactExtension(ApexPages.StandardController stdController) {
        Contact currentContact = (Contact) stdController.getRecord();
        this.cont = [SELECT AccountId FROM Contact WHERE Id = :currentContact.Id];
    }

    public PageReference deleteContact() {
        delete cont;
        PageReference pageRef = new PageReference('/' + cont.AccountId);

        return pageRef;
    }

    public PageReference cancelDeletion() {
        PageReference pageRef = new PageReference('/' + cont.Id);

        return pageRef;
    }
}