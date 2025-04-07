public without sharing class DeleteAccountTeamMemberController {
    public AccountTeamMember atmRecord { get; set; }

    public DeleteAccountTeamMemberController(ApexPages.StandardController stdController) {
        atmRecord = (AccountTeamMember) stdController.getRecord();
        System.debug('Delete Controller: atmRecord.Id = ' + atmRecord.Id);
    }
    
    public PageReference deleteRecord() {
        try {
            AccountTeamMember atMember = [
                SELECT AccountId 
                FROM AccountTeamMember 
                WHERE Id = :atmRecord.Id 
                LIMIT 1
            ];
            
            deleteTeamMember(atmRecord.Id);
            
            // Redirect to the parent Account record.
            PageReference acctPage = new PageReference('/' + atMember.AccountId);
            acctPage.setRedirect(true);
            return acctPage;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error deleting record: ' + ex.getMessage()));
            System.debug('Error in deleteRecord: ' + ex.getMessage());
            return null;
        }
    }

    public static void deleteTeamMember(Id atmId) {
        AccountTeamMember recordToDelete = [SELECT Id FROM AccountTeamMember WHERE Id = :atmId];
        delete recordToDelete;
    }
}
