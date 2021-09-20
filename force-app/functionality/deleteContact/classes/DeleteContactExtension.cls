public without sharing class DeleteContactExtension {
    private final Contact cont;
    private List<Task> tasks = new List<Task>();
    private List<Event> events  = new List<Event>();

    public deleteContactExtension(ApexPages.StandardController stdController) {
        Contact currentContact = (Contact) stdController.getRecord();
        this.cont = [SELECT AccountId FROM Contact WHERE Id = :currentContact.Id];
    }

    public PageReference deleteContact() {
        for (Task t :[SELECT Id,WhoId FROM Task WHERE WhoId = :cont.Id]) {
            t.WhoId = null;
            tasks.add(t);
        }

        for (Event e :[SELECT Id,WhoId FROM Event WHERE WhoId = :cont.Id]) {
            e.WhoId = null;
            events.add(e);
        }

        if(!tasks.isEmpty()){
            update tasks;
        }
        if(!events.isEmpty()){
            update events;
        }

        delete cont;
        PageReference pageRef = new PageReference('/' + cont.AccountId);

        return pageRef;
    }

    public PageReference cancelDeletion() {
        PageReference pageRef = new PageReference('/' + cont.Id);

        return pageRef;
    }
}
