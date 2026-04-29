public with sharing class TAG_EmployerInquiryConversion {
    // Alle NavTask__c skal ha samme kilde
    private static final String NAVTASK_TO_INQUIRY_SOURCE = 'Kontaktsenteret';

    // For NavTask__c CRM_Theme__c to EmployerInquiry__c TAG_Theme__c
    private static final Map<string, string> NAVTASK_TO_INQUIRY_THEME = new Map<string, string>{
        'Rekruttere og inkludere' => 'Rekruttere og inkludere',
        'Forebygge sykefravær og redusere frafall' => 'Forebygge og redusere fravær'
    };

    // For NavTask__c CRM_SubTheme__c to EmployerInquiry__c TAG_SubTheme__c
    private static final Map<string, string> NAVTASK_TO_INQUIRY_SUBTHEME = new Map<string, string>{
        'Helse i arbeid' => null,
        'Redusere sykefravær' => 'Redusere sykefravær',
        'Forbyggende arbeidsmiljøarbeid' => null,
        'Jobbmesser og møteplasser' => 'Jobbmesser og møteplass',
        'Rekrutteringsoppdrag' => 'Rekruttering uten virkemidler',
        'Informasjon om NAVs tjenester' => 'Informasjon og relasjonsbygging',
        'Inkluderende rekruttering' => 'Inkludering med virkemidler',
        'Permittering' => null,
        'Masseoppsigelser' => null,
        'Tiltaksøkonomi' => null,
        'Lønnskompensasjon' => null,
        'Generell sykefraværsoppfølging' => null,
        'Ungdomsløftet' => 'Ungdomsløftet'
    };

    // For CustomOpportunity__c Source__c to EmployerInquiry__c TAG_Source__c
    private static final Map<string, string> OPPORTUNITY_TO_INQUIRY_SOURCE = new Map<string, string>{
        'Kontaktskjema' => 'Kontaktskjema',
        'Arbeidsplassen' => 'Arbeidsplassen.no'
    };
    // For CustomOpportunity__c InquiryCategory__c to EmployerInquiry__c TAG_Theme__c
    private static final Map<string, string> OPPORTUNITY_TO_INQUIRY_THEME = new Map<string, string>{
        'Skal ansette' => 'Rekruttere og inkludere',
        'Forebygge sykefravær' => 'Forebygge og redusere fravær',
        'Ungdomsløftet' => 'Rekruttere og inkludere',
        'Tiltak' => null
    };
    // For CustomOpportunity__c InquiryCategory__c to EmployerInquiry__c TAG_SubTheme__c
    private static final Map<string, string> OPPORTUNITY_TO_INQUIRY_SUBTHEME = new Map<string, string>{
        'Skal ansette' => null,
        'Forebygge sykefravær' => null,
        'Ungdomsløftet' => 'Ungdomsløftet',
        'Tiltak' => null
    };

    public class ConversionRequest {
        @InvocableVariable(
            label='Konverter Nav-oppgaver'
            description='Konverter Nav-oppgaver til henvendelser'
            required=true
        )
        public Boolean convertNavTasks;

        @InvocableVariable(
            label='Konverter Custom Opportunities'
            description='Konverter Custom Opportunities til henvendelser'
            required=true
        )
        public Boolean convertCustomOpportunities;

        @InvocableVariable(
            label='Opprettet på eller etter'
            description='Kun konverter records opprettet på eller etter denne datoen'
            required=true
        )
        public Datetime createdOnOrAfter;
    }

    public class ConversionResult {
        @InvocableVariable
        public Integer successCount;
        @InvocableVariable
        public Integer errorCount;
        @InvocableVariable
        public List<String> errorMessages;
    }

    @InvocableMethod(
        label='Konverter til arbeidsgiverhenvendelser'
        description='Konverterer ukonverterte Nav-oppgaver og Custom Opportunities til EmployerInquiry'
    )
    public static List<ConversionResult> convertAllToEmployerInquiries(List<ConversionRequest> requests) {
        ConversionRequest request = requests[0];
        Datetime createdOnOrAfter = request.createdOnOrAfter;
        List<EmployerInquiry__c> employerInquiries = new List<EmployerInquiry__c>();
        if (request.convertNavTasks) {
            List<NavTask__c> navTasks = getNavTaskRecords(createdOnOrAfter);
            employerInquiries.addAll(createEmployerInquiriesFromNavTasks(navTasks));
        }
        if (request.convertCustomOpportunities) {
            List<CustomOpportunity__c> opportunities = getCustomOpportunityRecords(createdOnOrAfter);
            employerInquiries.addAll(createEmployerInquiriesFromOpportunities(opportunities));
        }

        ConversionResult result = new ConversionResult();
        result.successCount = 0;
        result.errorCount = 0;
        result.errorMessages = new List<String>();

        if (!employerInquiries.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.insert(employerInquiries, false);
            for (Database.SaveResult sr : saveResults) {
                if (sr.isSuccess()) {
                    result.successCount++;
                } else {
                    result.errorCount++;
                    result.errorMessages.add(sr.getErrors()[0].getMessage());
                }
            }
        }

        return new List<ConversionResult>{ result };
    }

    private static List<NavTask__c> getNavTaskRecords(Datetime createdOnOrAfter) {
        return [
            SELECT
                Id,
                Name,
                CRM_Account__c,
                CRM_AdditionalInformation__c,
                CRM_ConversationNote__c,
                CRM_DueDate__c,
                CRM_NavUnit__c,
                CRM_SubTheme__c,
                CRM_Theme__c,
                OwnerId,
                CreatedDate
            FROM NavTask__c
            WHERE
                CRM_Status__c = 'Ny'
                AND Recordtype.Name = 'Employer'
                AND CreatedDate >= :createdOnOrAfter
                AND Id NOT IN (SELECT TAG_Converted_NAV_Task__c FROM EmployerInquiry__c)
            LIMIT 5000
        ];
    }

    private static List<CustomOpportunity__c> getCustomOpportunityRecords(Datetime createdOnOrAfter) {
        return [
            SELECT
                Id,
                Name,
                Account__c,
                Contact__c,
                InquiryCategory__c,
                INT_MunicipalityNumber__c,
                Notes__c,
                OwnerId,
                RecordTypeId,
                Source__c,
                TAG_IsFromArticle__c,
                TAG_JobPosting__c,
                TAG_NavUnit__c,
                TAG_No_person_information__c,
                TAG_OrganizationNameFromForm__c,
                TAG_UltimateSource__c,
                TAG_DueDateTime__c,
                CreatedDate
            FROM CustomOpportunity__c
            WHERE
                RecordType.Name = 'Inclusion'
                AND InclusionStage__c = 'Ny henvendelse'
                AND Source__c IN ('Kontaktskjema', 'Arbeidsplassen')
                AND CreatedDate >= :createdOnOrAfter
                AND Id NOT IN (SELECT TAG_Converted_Custom_Opportunity__c FROM EmployerInquiry__c)
            LIMIT 5000
        ];
    }

    private static List<EmployerInquiry__c> createEmployerInquiriesFromNavTasks(List<NavTask__c> navTasks) {
        List<EmployerInquiry__c> employerInquiries = new List<EmployerInquiry__c>();
        for (NavTask__c navTask : navTasks) {
            EmployerInquiry__c employerInquiry = new EmployerInquiry__c();
            employerInquiry.TAG_Converted_NAV_Task__c = navTask.Id;
            employerInquiry.OwnerId = navTask.OwnerId;
            employerInquiry.Name = navTask.Name;
            employerInquiry.TAG_Account__c = navTask.CRM_Account__c;
            employerInquiry.TAG_Message__c = 'Samtalereferat: ' + navTask.CRM_ConversationNote__c;
            employerInquiry.TAG_Message__c += '\nOppgave til NAV-enhet: ' + navTask.CRM_AdditionalInformation__c;
            employerInquiry.TAG_DueDate__c = navTask.CRM_DueDate__c;
            employerInquiry.TAG_DueDateTime__c = navTask.CRM_DueDate__c != null
                ? Datetime.newInstance(
                      navTask.CRM_DueDate__c.year(),
                      navTask.CRM_DueDate__c.month(),
                      navTask.CRM_DueDate__c.day(),
                      23,
                      59,
                      59
                  )
                : null;
            employerInquiry.TAG_NavUnit__c = navTask.CRM_NavUnit__c;
            employerInquiry.TAG_Status__c = 'Ny henvendelse';
            employerInquiry.TAG_SubTheme__c = NAVTASK_TO_INQUIRY_SUBTHEME.get(navTask.CRM_SubTheme__c);
            employerInquiry.TAG_Theme__c = NAVTASK_TO_INQUIRY_THEME.get(navTask.CRM_Theme__c);
            employerInquiry.TAG_Source__c = NAVTASK_TO_INQUIRY_SOURCE;
            employerInquiry.TAG_RecievedDateTime__c = navTask.CreatedDate;
            employerInquiries.add(employerInquiry);
        }
        return employerInquiries;
    }

    private static List<EmployerInquiry__c> createEmployerInquiriesFromOpportunities(
        List<CustomOpportunity__c> opportunities
    ) {
        List<EmployerInquiry__c> employerInquiries = new List<EmployerInquiry__c>();
        for (CustomOpportunity__c opp : opportunities) {
            EmployerInquiry__c employerInquiry = new EmployerInquiry__c();
            employerInquiry.TAG_Converted_Custom_Opportunity__c = opp.Id;
            employerInquiry.Name = opp.InquiryCategory__c;
            employerInquiry.OwnerId = opp.OwnerId;
            employerInquiry.TAG_Account__c = opp.Account__c;
            employerInquiry.TAG_Contact__c = opp.Contact__c;
            employerInquiry.TAG_Status__c = 'Ny henvendelse';
            employerInquiry.TAG_Message__c = opp.Notes__c;
            employerInquiry.TAG_NoPersonInformation__c = opp.TAG_No_person_information__c;
            employerInquiry.TAG_NavUnit__c = opp.TAG_NavUnit__c;
            employerInquiry.TAG_RelatedJobPosting__c = opp.TAG_JobPosting__c;
            employerInquiry.TAG_DueDateTime__c = opp.TAG_DueDateTime__c;
            employerInquiry.TAG_DueDate__c = opp.TAG_DueDateTime__c != null
                ? Date.newInstance(
                      opp.TAG_DueDateTime__c.year(),
                      opp.TAG_DueDateTime__c.month(),
                      opp.TAG_DueDateTime__c.day()
                  )
                : null;
            employerInquiry.TAG_Source__c = OPPORTUNITY_TO_INQUIRY_SOURCE.get(opp.Source__c);
            employerInquiry.TAG_Theme__c = OPPORTUNITY_TO_INQUIRY_THEME.get(opp.InquiryCategory__c);
            employerInquiry.TAG_SubTheme__c = OPPORTUNITY_TO_INQUIRY_SUBTHEME.get(opp.InquiryCategory__c);
            employerInquiries.add(employerInquiry);
        }
        return employerInquiries;
    }
}
