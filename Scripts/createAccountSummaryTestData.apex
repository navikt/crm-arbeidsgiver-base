// Creates test data for the Arbeidsgiveroversikt component (accountSummaryHorizontal) on one employer.
// Ongoing: 2 planned meetings, 1 active agreement, 1 active measure (tiltak), 2 open opportunities.
// History spread over the last 12 months, so 6 mnd and 12 mnd show different numbers.
// All records are marked with MARKER so they can be removed with Scripts/deleteAccountSummaryTestData.apex.
//
// sf apex run --target-org preprod --file Scripts/createAccountSummaryTestData.apex

final Id ACCOUNT_ID = '001ba00000DN7xmAAD';
final String MARKER = '[TESTDATA Oversikt]';

final String ACTIVITY_TYPE = 'Rekruttere og inkludere';
final String SERVICE = 'Inkluderende rekruttering';
final Id TASK_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverTask').getRecordTypeId();
final Id EVENT_RT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('ArbeidsgiverEvent').getRecordTypeId();
final Id AGREEMENT_RT = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
    .get('EmployerAgreement')
    .getRecordTypeId();

// A day in the month that is monthsBack months ago (never later than today)
Date dayInMonth(Integer monthsBack, Integer day) {
    Date d = Date.today().toStartOfMonth().addMonths(-monthsBack).addDays(day - 1);
    return d > Date.today() ? Date.today() : d;
}

Datetime at(Date d, Integer hour) {
    return Datetime.newInstance(d, Time.newInstance(hour, 0, 0, 0));
}

Event meeting(String subject, Datetime startsAt) {
    return new Event(
        RecordTypeId = EVENT_RT,
        Subject = MARKER + ' ' + subject,
        WhatId = ACCOUNT_ID,
        RelatedToAccount__c = ACCOUNT_ID,
        TAG_ActivityType__c = ACTIVITY_TYPE,
        TAG_service__c = SERVICE,
        TAG_NoPersonInformation__c = true,
        StartDateTime = startsAt,
        EndDateTime = startsAt.addHours(1),
        OwnerId = UserInfo.getUserId()
    );
}

Task contact(String type, String subject, Date activityDate) {
    return new Task(
        RecordTypeId = TASK_RT,
        Subject = MARKER + ' ' + subject,
        WhatId = ACCOUNT_ID,
        RelatedToAccount__c = ACCOUNT_ID,
        TAG_ActivityType__c = ACTIVITY_TYPE,
        TAG_service__c = SERVICE,
        TAG_NoPersonInformation__c = true,
        Type = type,
        ActivityDate = activityDate,
        Status = 'Completed',
        OwnerId = UserInfo.getUserId()
    );
}

Account account = [SELECT Id, Name FROM Account WHERE Id = :ACCOUNT_ID];

// ---------------------------------------------------------------- ONGOING

// 2 planned meetings
List<Event> events = new List<Event>{
    meeting('Oppstartsmøte rekruttering', at(Date.today().addDays(2), 10)),
    meeting('Besøk på arbeidsplassen', at(Date.today().addDays(9), 13))
};

// 1 active agreement (+ 2 that ended within the last 12 months)
Contact employerContact = new Contact(
    FirstName = 'Testkontakt',
    LastName = MARKER,
    AccountId = ACCOUNT_ID,
    TAG_Informed__c = true
);
insert employerContact;

List<Contract__c> agreements = new List<Contract__c>{
    new Contract__c(
        RecordTypeId = AGREEMENT_RT,
        TAG_Account__c = ACCOUNT_ID,
        TAG_Category__c = 'Markedssamarbeid',
        TAG_Status__c = 'Godkjent',
        TAG_StartDate__c = Date.today().addDays(-60),
        TAG_EndDate__c = Date.today().addMonths(10),
        TAG_Description__c = MARKER + ' Aktiv avtale',
        TAG_Contact__c = employerContact.Id,
        TAG_InternalContact__c = UserInfo.getUserId(),
        TAG_ExternalURL__c = 'https://www.nav.no'
    ),
    new Contract__c(
        RecordTypeId = AGREEMENT_RT,
        TAG_Account__c = ACCOUNT_ID,
        TAG_Category__c = 'Rekrutteringsavtale',
        TAG_Status__c = 'Godkjent',
        TAG_StartDate__c = dayInMonth(11, 1),
        TAG_EndDate__c = dayInMonth(4, 15),
        TAG_Description__c = MARKER + ' Avsluttet avtale (4 mnd siden)',
        TAG_Contact__c = employerContact.Id,
        TAG_InternalContact__c = UserInfo.getUserId(),
        TAG_ExternalURL__c = 'https://www.nav.no'
    ),
    new Contract__c(
        RecordTypeId = AGREEMENT_RT,
        TAG_Account__c = ACCOUNT_ID,
        TAG_Category__c = 'Markedssamarbeid',
        TAG_Status__c = 'Godkjent',
        TAG_StartDate__c = dayInMonth(11, 5),
        TAG_EndDate__c = dayInMonth(9, 20),
        TAG_Description__c = MARKER + ' Avsluttet avtale (9 mnd siden)',
        TAG_Contact__c = employerContact.Id,
        TAG_InternalContact__c = UserInfo.getUserId(),
        TAG_ExternalURL__c = 'https://www.nav.no'
    )
};
insert agreements;

// 1 active measure (+ 2 that ended within the last 12 months)
insert new List<Workfare__c>{
    new Workfare__c(
        Account__c = ACCOUNT_ID,
        Name = MARKER + ' Aktivt tiltak',
        Type__c = 'ARBEIDSTRENING',
        Status__c = 'GJENNOMFØRES',
        StartDate__c = Date.today().addDays(-30),
        EndDate__c = Date.today().addMonths(4)
    ),
    new Workfare__c(
        Account__c = ACCOUNT_ID,
        Name = MARKER + ' Avsluttet tiltak (3 mnd siden)',
        Type__c = 'MIDLERTIDIG_LONNSTILSKUDD',
        Status__c = 'AVSLUTTET',
        StartDate__c = dayInMonth(9, 1),
        EndDate__c = dayInMonth(3, 10)
    ),
    new Workfare__c(
        Account__c = ACCOUNT_ID,
        Name = MARKER + ' Avsluttet tiltak (8 mnd siden)',
        Type__c = 'ARBEIDSTRENING',
        Status__c = 'AVSLUTTET',
        StartDate__c = dayInMonth(11, 1),
        EndDate__c = dayInMonth(8, 10)
    )
};

// 2 open opportunities (+ 2 closed within the last 12 months). Short Description is max 30 characters.
insert new List<CustomOpportunity__c>{
    new CustomOpportunity__c(
        Account__c = ACCOUNT_ID,
        Source__c = 'Kontaktskjema',
        InclusionStage__c = 'Ny henvendelse',
        InquiryCategory__c = 'Skal ansette',
        TAG_Short_Description__c = MARKER + ' Åpen 1',
        TAG_No_person_information__c = true
    ),
    new CustomOpportunity__c(
        Account__c = ACCOUNT_ID,
        Source__c = 'Kontaktskjema',
        InclusionStage__c = 'Avklaring',
        InquiryCategory__c = 'Tiltak',
        TAG_Short_Description__c = MARKER + ' Åpen 2',
        TAG_No_person_information__c = true
    ),
    new CustomOpportunity__c(
        Account__c = ACCOUNT_ID,
        Source__c = 'Kontaktskjema',
        InclusionStage__c = 'Avsluttet',
        Result__c = 'Arbeidstrening',
        InquiryCategory__c = 'Skal ansette',
        TAG_Resolved_Date_Time__c = at(dayInMonth(2, 12), 10),
        TAG_Short_Description__c = MARKER + ' Lukket 1',
        TAG_No_person_information__c = true
    ),
    new CustomOpportunity__c(
        Account__c = ACCOUNT_ID,
        Source__c = 'Kontaktskjema',
        InclusionStage__c = 'Avsluttet',
        Result__c = 'Skal rekruttere selv',
        InquiryCategory__c = 'Skal ansette',
        TAG_Resolved_Date_Time__c = at(dayInMonth(7, 5), 10),
        TAG_Short_Description__c = MARKER + ' Lukket 2',
        TAG_No_person_information__c = true
    )
};

// ---------------------------------------------------------------- HISTORY

// Completed meetings
for (Integer monthsBack : new List<Integer>{ 1, 2, 4, 6, 8, 10 }) {
    events.add(meeting('Gjennomført møte', at(dayInMonth(monthsBack, 18), 10)));
}
insert events;

// Logged calls (every month), e-mails (every 3rd month) and SMS
List<Task> tasks = new List<Task>();
for (Integer monthsBack = 0; monthsBack < 12; monthsBack++) {
    tasks.add(contact('Call', 'Telefonsamtale', dayInMonth(monthsBack, 6)));
}
for (Integer monthsBack : new List<Integer>{ 0, 3, 6, 9 }) {
    tasks.add(contact('Email', 'E-post', dayInMonth(monthsBack, 14)));
}
for (Integer monthsBack : new List<Integer>{ 1, 7 }) {
    tasks.add(contact('SMS', 'SMS', dayInMonth(monthsBack, 22)));
}
insert tasks;

// Direct-reported job postings that have expired
insert new List<JobPosting__c>{
    new JobPosting__c(
        Account__c = ACCOUNT_ID,
        Title__c = MARKER + ' Butikkmedarbeider',
        Source__c = 'DIR',
        Status__c = 'INACTIVE',
        Published__c = at(dayInMonth(6, 1), 9),
        Expires__c = at(dayInMonth(5, 20), 23)
    ),
    new JobPosting__c(
        Account__c = ACCOUNT_ID,
        Title__c = MARKER + ' Lagermedarbeider',
        Source__c = 'DIR',
        Status__c = 'INACTIVE',
        Published__c = at(dayInMonth(11, 1), 9),
        Expires__c = at(dayInMonth(10, 3), 23)
    )
};

// Placements and presented candidates
insert new List<CandidateOutcome__c>{
    new CandidateOutcome__c(
        Account__c = ACCOUNT_ID,
        Title__c = MARKER + ' Formidling 1',
        Category__c = 'FORMIDLING',
        Result__c = 'FATT_JOBBEN',
        TimeRegistered__c = at(dayInMonth(1, 9), 12)
    ),
    new CandidateOutcome__c(
        Account__c = ACCOUNT_ID,
        Title__c = MARKER + ' Formidling 2',
        Category__c = 'STILLING',
        Result__c = 'FATT_JOBBEN',
        TimeRegistered__c = at(dayInMonth(5, 11), 12)
    ),
    new CandidateOutcome__c(
        Account__c = ACCOUNT_ID,
        Title__c = MARKER + ' Presentert kandidat',
        Category__c = 'STILLING',
        Result__c = 'PRESENTERT',
        TimeRegistered__c = at(dayInMonth(9, 16), 12)
    )
};

System.debug(LoggingLevel.ERROR, 'Test data created for ' + account.Name + ' (' + ACCOUNT_ID + ')');
