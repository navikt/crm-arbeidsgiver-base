// Creates one open employer inquiry (henvendelse) for the Arbeidsgiveroversikt component (accountSummaryHorizontal).
// It shows as «Åpne henvendelser» on the employer and makes the account count as having ongoing activity.
// The inquiry is marked with MARKER so it can be removed with Scripts/deleteAccountSummaryTestData.apex.
//
// sf apex run --target-org preprod --file Scripts/createAccountSummaryInquiry.apex

final Id ACCOUNT_ID = '001ba00000DN7xmAAD';
final String MARKER = '[TESTDATA Oversikt]';

Account account = [SELECT Id, Name FROM Account WHERE Id = :ACCOUNT_ID];

EmployerInquiry__c inquiry = new EmployerInquiry__c(
    TAG_Account__c = ACCOUNT_ID,
    TAG_Status__c = 'Ny henvendelse',
    // Source must be set, otherwise the TAG_Employer_Inquiry_Error flow blocks the insert
    TAG_Source__c = 'Kontaktsenteret',
    TAG_Theme__c = 'Rekruttere og inkludere',
    TAG_WebFormAccountName__c = MARKER + ' ' + account.Name,
    TAG_Message__c = 'Testhenvendelse for arbeidsgiveroversikten. Arbeidsgiver ønsker hjelp til å rekruttere butikkmedarbeidere.'
);
insert inquiry;

System.debug(LoggingLevel.ERROR, 'Inquiry ' + inquiry.Id + ' created for ' + account.Name + ' (' + ACCOUNT_ID + ')');
