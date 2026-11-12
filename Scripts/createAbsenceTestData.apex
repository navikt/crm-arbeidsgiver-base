Organization organization = [SELECT IsSandbox, TrialExpirationDate FROM Organization LIMIT 1];
System.assert(
    organization.IsSandbox && organization.TrialExpirationDate != null,
    'Run this script in a scratch org only.'
);

Map<String, String> accountNames = new Map<String, String>{
    '990000099' => 'Absence Chart Test',
    '990000100' => 'Absence Chart Test - Missing quarter',
    '990000101' => 'Absence Chart Test - Missing start',
    '990000102' => 'Absence Chart Test - Missing end'
};
Map<String, Set<Integer>> missingQuartersByCode = new Map<String, Set<Integer>>{
    '990000099' => new Set<Integer>(),
    '990000100' => new Set<Integer>{ 6 },
    '990000101' => new Set<Integer>{ 0, 1 },
    '990000102' => new Set<Integer>{ 10, 11 }
};
String industryCode = '43210';
String yearKey = '\u00e5rstall';
Map<String, Account> accountsByCode = new Map<String, Account>();
for (Account employer : [
    SELECT Id, Name, INT_OrganizationNumber__c
    FROM Account
    WHERE INT_OrganizationNumber__c IN :accountNames.keySet()
]) {
    String code = employer.INT_OrganizationNumber__c;
    System.assert(!accountsByCode.containsKey(code), 'Multiple accounts use the test organization number: ' + code);
    System.assertEquals(
        accountNames.get(code),
        employer.Name,
        'The test organization number belongs to another account.'
    );
    accountsByCode.put(code, employer);
}
List<Account> newAccounts = new List<Account>();
for (String code : accountNames.keySet()) {
    if (!accountsByCode.containsKey(code)) {
        Account employer = new Account(
            Name = accountNames.get(code),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Employer')
                .getRecordTypeId(),
            INT_OrganizationNumber__c = code,
            INT_OrganizationalStructure__c = 'BEDR',
            INT_IndustryCode__c = '43.210'
        );
        accountsByCode.put(code, employer);
        newAccounts.add(employer);
    }
}
insert newAccounts;

Date currentQuarter = Date.newInstance(Date.today().year(), 1 + 3 * ((Date.today().month() - 1) / 3), 1);
List<Absence__c> industryAbsences = new List<Absence__c>();
List<Absence__c> employerAbsences = new List<Absence__c>();
Map<String, Absence__c> expectedByKey = new Map<String, Absence__c>();
Set<String> omittedKeys = new Set<String>();
List<String> codes = new List<String>{ industryCode };
codes.addAll(accountNames.keySet());
List<Decimal> seasonalPercent = new List<Decimal>{ 6.8, 5.9, 4.7, 6.2 };

for (String code : codes) {
    Boolean isEmployer = accountsByCode.containsKey(code);
    String category = isEmployer ? 'VIRKSOMHET' : 'N\u00c6RINGSKODE';
    Decimal possibleDays = isEmployer ? 5000 : 500000;
    List<Decimal> lostDaysHistory = new List<Decimal>();
    for (Integer index = 0; index < 15; index++) {
        Date period = currentQuarter.addMonths((index - 15) * 3);
        Integer year = period.year();
        Integer quarter = 1 + (period.month() - 1) / 3;
        Decimal percent = (seasonalPercent[quarter - 1] + (isEmployer ? -1.2 + index * 0.1 : index * 0.03)).setScale(1);
        Decimal lostDays = possibleDays * percent / 100;
        lostDaysHistory.add(lostDays);
        if (index < 3) {
            continue;
        }
        if (isEmployer && missingQuartersByCode.get(code).contains(index - 3)) {
            omittedKeys.add(code + year + quarter);
            continue;
        }

        Decimal rollingLostDays = 0;
        List<Map<String, Object>> quarters = new List<Map<String, Object>>();
        for (Integer offset = 0; offset < 4; offset++) {
            rollingLostDays += lostDaysHistory[index - offset];
            Date rollingPeriod = period.addMonths(-3 * offset);
            quarters.add(
                new Map<String, Object>{
                    yearKey => rollingPeriod.year(),
                    'kvartal' => 1 + (rollingPeriod.month() - 1) / 3
                }
            );
        }
        Map<String, Object> publishedQuarter = new Map<String, Object>{
            yearKey => year,
            'kvartal' => quarter,
            'prosent' => percent,
            'tapteDagsverk' => lostDays,
            'muligeDagsverk' => possibleDays,
            'antallPersoner' => isEmployer ? 100 : 10000,
            'erMaskert' => false
        };
        Decimal rollingPercent = (rollingLostDays / (possibleDays * 4) * 100).setScale(1);
        Map<String, Object> last4Quarters = new Map<String, Object>{
            'prosent' => rollingPercent,
            'tapteDagsverk' => rollingLostDays,
            'muligeDagsverk' => possibleDays * 4,
            'erMaskert' => false,
            'kvartaler' => quarters
        };
        String key = isEmployer
            ? code + year + quarter
            : EncodingUtil.base64Encode(
                  Blob.valueOf(
                      JSON.serialize(
                          new Map<String, Object>{
                              'kategori' => category,
                              'kode' => code,
                              yearKey => year,
                              'kvartal' => quarter
                          }
                      )
                  )
              );
        Absence__c absence = new Absence__c(
            CRM_Key__c = key,
            CRM_AbsenceCategory__c = category,
            CRM_Code__c = code,
            CRM_Year__c = year,
            CRM_Quarter__c = quarter,
            CRM_Percent__c = percent,
            CRM_LostDaysWork__c = lostDays,
            CRM_PossibleDaysWork__c = possibleDays,
            CRM_NumberOfPeople__c = isEmployer ? 100 : 10000,
            CRM_IsHidden__c = false,
            CRM_Last4QuartersPercent__c = rollingPercent,
            CRM_Last4QuartersLostDaysWork__c = rollingLostDays,
            CRM_Last4QuartersPossibleDaysWork__c = possibleDays * 4,
            CRM_Last4QuartersIsHidden__c = false,
            JsonPayload__c = JSON.serialize(
                new Map<String, Object>{
                    'kategori' => category,
                    'kode' => code,
                    'sistePubliserteKvartal' => publishedQuarter,
                    'siste4Kvartal' => last4Quarters
                }
            )
        );
        if (isEmployer) {
            absence.CRM_Account__c = accountsByCode.get(code).Id;
            absence.CRM_OrganizationNumber__c = code;
            absence.CRM_IndustryCode__c = industryCode;
            employerAbsences.add(absence);
            expectedByKey.put(key, absence);
        } else {
            industryAbsences.add(absence);
        }
    }
}

upsert industryAbsences CRM_Key__c;
Map<String, Absence__c> industryByQuarter = new Map<String, Absence__c>();
for (Absence__c absence : industryAbsences) {
    industryByQuarter.put(absence.CRM_Year__c + '-' + absence.CRM_Quarter__c, absence);
}
for (Absence__c absence : employerAbsences) {
    String quarter = absence.CRM_Year__c + '-' + absence.CRM_Quarter__c;
    absence.CRM_AbsenceIndustryCode__c = industryByQuarter.get(quarter).Id;
}
upsert employerAbsences CRM_Key__c;

List<Absence__c> omittedAbsences = [
    SELECT Id
    FROM Absence__c
    WHERE CRM_Account__c IN :accountsByCode.values() AND CRM_Key__c IN :omittedKeys
];
delete omittedAbsences;

Set<String> scenarioKeys = new Set<String>(expectedByKey.keySet());
scenarioKeys.addAll(omittedKeys);
List<Absence__c> savedAbsences = [
    SELECT CRM_Key__c, CRM_Year__c, CRM_Quarter__c, CRM_Percent__c, CRM_IndustryCodePercent__c
    FROM Absence__c
    WHERE CRM_Account__c IN :accountsByCode.values() AND CRM_Key__c IN :scenarioKeys
];
System.assertEquals(expectedByKey.size(), savedAbsences.size(), 'Unexpected number of employer quarters.');
Set<String> savedKeys = new Set<String>();
for (Absence__c absence : savedAbsences) {
    System.assert(!omittedKeys.contains(absence.CRM_Key__c), 'Expected quarter to be absent: ' + absence.CRM_Key__c);
    System.assert(savedKeys.add(absence.CRM_Key__c), 'Duplicate quarter: ' + absence.CRM_Key__c);
    System.assertEquals(expectedByKey.get(absence.CRM_Key__c).CRM_Percent__c, absence.CRM_Percent__c);
    String quarter = absence.CRM_Year__c + '-' + absence.CRM_Quarter__c;
    System.assertEquals(industryByQuarter.get(quarter).CRM_Percent__c, absence.CRM_IndustryCodePercent__c);
}
System.assertEquals(expectedByKey.keySet(), savedKeys, 'Expected exactly the scenario quarters.');
for (String code : accountNames.keySet()) {
    System.debug(
        accountNames.get(code) +
            ': ' +
            (12 - missingQuartersByCode.get(code).size()) +
            ' quarters. Account: ' +
            accountsByCode.get(code).Id
    );
}
