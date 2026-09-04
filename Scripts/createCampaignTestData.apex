// Creates test data for the "TAG Move or Copy Campaign Members" flow.
// 20 accounts, 4 custom campaigns, 10-20 members per campaign.
// sf apex run --file Scripts/createCampaignTestData.apex

final String PREFIX = 'CCM Test';

// Employer record type if it exists in the org, otherwise default
Id employerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().containsKey('Employer')
    ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Employer').getRecordTypeId()
    : null;

// NAV unit is optional, just reuse one if the org already has some
List<NavUnit__c> navUnits = [SELECT Id FROM NavUnit__c LIMIT 1];
Id navUnitId = navUnits.isEmpty() ? null : navUnits[0].Id;

// ---- Accounts ----
List<String> municipalities = new List<String>{ '3003', '0301', '4601', '5001', '1103' };
List<Account> accounts = new List<Account>();

for (Integer i = 1; i <= 20; i++) {
    Account acc = new Account(
        Name = PREFIX + ' Bedrift ' + String.valueOf(i).leftPad(2, '0'),
        INT_OrganizationNumber__c = '99' + String.valueOf(1000000 + i),
        INT_MunicipalityNumber__c = municipalities[Math.mod(i, municipalities.size())],
        INT_OrganizationalStructure__c = 'BEDR'
    );
    if (employerRecordTypeId != null) {
        acc.RecordTypeId = employerRecordTypeId;
    }
    if (navUnitId != null) {
        acc.TAG_NavUnit__c = navUnitId;
    }
    accounts.add(acc);
}
insert accounts;

// ---- Contacts, one per account ----
List<Contact> contacts = new List<Contact>();
for (Integer i = 0; i < accounts.size(); i++) {
    contacts.add(
        new Contact(
            FirstName = 'Kontakt',
            LastName = PREFIX + ' ' + String.valueOf(i + 1).leftPad(2, '0'),
            AccountId = accounts[i].Id,
            Email = 'ccm.test' + (i + 1) + '@example.com',
            TAG_Informed__c = true,
            TAG_BypassDuplicate__c = true
        )
    );
}
insert contacts;

// ---- Campaigns ----
List<String> campaignTypes = new List<String>{
    'Sommerjobbkampanje',
    'Inkluderingskampanje',
    'Fylkeskampanje',
    'Bedriftsundersøkelse'
};

List<CustomCampaign__c> campaigns = new List<CustomCampaign__c>();
for (Integer i = 0; i < campaignTypes.size(); i++) {
    CustomCampaign__c camp = new CustomCampaign__c(
        Name = PREFIX + ' ' + campaignTypes[i] + ' ' + Date.today().year(),
        Type__c = campaignTypes[i],
        Status__c = 'Åpen',
        StartDate__c = Date.today(),
        EndDate__c = Date.today().addDays(45),
        Description__c = 'Testkampanje opprettet av createCampaignTestData.apex'
    );
    if (navUnitId != null) {
        camp.NAV_Unit__c = navUnitId;
    }
    campaigns.add(camp);
}
insert campaigns;

// Statuses that are valid for each campaign type
Map<String, List<String>> statusesByType = new Map<String, List<String>>{
    'Sommerjobbkampanje' => new List<String>{ 'Ny', 'Sendt informasjon', 'Interessert', 'Inngått avtale', 'Frafalt' },
    'Inkluderingskampanje' => new List<String>{ 'Ny', 'Sendt informasjon', 'Interessert', 'Ikke aktuell' },
    'Fylkeskampanje' => new List<String>{ 'Ny', 'Sendt informasjon', 'Inngått avtale', 'Ikke aktuell' },
    'Bedriftsundersøkelse' => new List<String>{ 'Ikke gjennomført', 'Gjennomført', 'Ikke aktuell' }
};

// ---- Campaign members, 10-20 per campaign ----
List<CustomCampaignMember__c> members = new List<CustomCampaignMember__c>();

for (Integer c = 0; c < campaigns.size(); c++) {
    CustomCampaign__c camp = campaigns[c];
    List<String> statuses = statusesByType.get(camp.Type__c);
    Integer memberCount = 10 + Math.mod(Math.abs(Crypto.getRandomInteger()), 11);

    for (Integer m = 0; m < memberCount; m++) {
        Integer accIndex = Math.mod(m + c * 3, accounts.size());

        members.add(
            new CustomCampaignMember__c(
                CustomCampaign__c = camp.Id,
                Account__c = accounts[accIndex].Id,
                Contact__c = contacts[accIndex].Id,
                Campaign_type__c = camp.Type__c,
                Status__c = statuses[Math.mod(m, statuses.size())],
                Kommentar__c = 'Testkommentar for ' + camp.Name + ' - medlem ' + (m + 1),
                NAV_Unit__c = navUnitId
            )
        );
    }
}
insert members;

System.debug('Created ' + accounts.size() + ' accounts');
System.debug('Created ' + contacts.size() + ' contacts');
System.debug('Created ' + campaigns.size() + ' campaigns');
System.debug('Created ' + members.size() + ' campaign members');
for (AggregateResult ar : [
    SELECT CustomCampaign__r.Name campaignName, COUNT(Id) total
    FROM CustomCampaignMember__c
    WHERE CustomCampaign__c IN :campaigns
    GROUP BY CustomCampaign__r.Name
]) {
    System.debug(ar.get('campaignName') + ': ' + ar.get('total') + ' medlemmer');
}
