// Removes the test data created by Scripts/createAccountSummaryTestData.apex and Scripts/createAccountSummaryInquiry.apex.
// Only records containing MARKER on the given employer are deleted.
//
// sf apex run --target-org preprod --file Scripts/deleteAccountSummaryTestData.apex

final Id ACCOUNT_ID = '001ba00000DN7xmAAD';
final String MARKER = '%[TESTDATA Oversikt]%';

List<SObject> toDelete = new List<SObject>();
toDelete.addAll([SELECT Id FROM Event WHERE RelatedToAccount__c = :ACCOUNT_ID AND Subject LIKE :MARKER]);
toDelete.addAll([SELECT Id FROM Task WHERE RelatedToAccount__c = :ACCOUNT_ID AND Subject LIKE :MARKER]);
List<Contact> testContacts = [SELECT Id FROM Contact WHERE AccountId = :ACCOUNT_ID AND LastName LIKE :MARKER];
// TAG_Description__c is a long text area and cannot be filtered, so agreements are found via the test contact
toDelete.addAll([SELECT Id FROM Contract__c WHERE TAG_Account__c = :ACCOUNT_ID AND TAG_Contact__c IN :testContacts]);
toDelete.addAll([SELECT Id FROM Workfare__c WHERE Account__c = :ACCOUNT_ID AND Name LIKE :MARKER]);
toDelete.addAll([
    SELECT Id
    FROM CustomOpportunity__c
    WHERE Account__c = :ACCOUNT_ID AND TAG_Short_Description__c LIKE :MARKER
]);
toDelete.addAll([SELECT Id FROM JobPosting__c WHERE Account__c = :ACCOUNT_ID AND Title__c LIKE :MARKER]);
toDelete.addAll([SELECT Id FROM CandidateOutcome__c WHERE Account__c = :ACCOUNT_ID AND Title__c LIKE :MARKER]);
delete toDelete;

// Contacts last, after the agreements that reference them are gone
delete testContacts;

System.debug(LoggingLevel.ERROR, 'Deleted ' + toDelete.size() + ' test records');

// Inquiries can only be deleted by the users listed in the TAG_Employer_Inquiry_No_Delete flow,
// so they are deleted separately and a failure does not undo the deletes above.
List<EmployerInquiry__c> testInquiries = [
    SELECT Id
    FROM EmployerInquiry__c
    WHERE TAG_Account__c = :ACCOUNT_ID AND TAG_WebFormAccountName__c LIKE :MARKER
];
for (Database.DeleteResult result : Database.delete(testInquiries, false)) {
    if (result.isSuccess()) {
        System.debug(LoggingLevel.ERROR, 'Deleted test inquiry ' + result.getId());
    } else {
        System.debug(LoggingLevel.ERROR, 'Could not delete test inquiry: ' + result.getErrors()[0].getMessage());
    }
}
