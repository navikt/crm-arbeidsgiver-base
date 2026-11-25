public with sharing class AccountSummaryConfig {
    public static final String AVTALE = 'avtale';
    public static final String STILLING = 'stilling';
    public static final String TILTAK = 'tiltak';
    public static final String IA = 'ia';
    public static final String MULIGHET = 'mulighet';
    public static final String HENVENDELSE = 'henvendelse';
    public static final String PLANLAGT = 'planlagt';
    public static final String NAVKONTAKT = 'navkontakt';
    public static final String MOTE = 'mote';
    public static final String KOMMUNIKASJON = 'kommunikasjon';
    public static final String FORMIDLING = 'formidling';

    public static final List<String> ONGOING_QUERY_KEYS = new List<String>{
        AVTALE,
        STILLING,
        TILTAK,
        IA,
        MULIGHET,
        HENVENDELSE
    };

    public static final List<String> HISTORY_KEYS = new List<String>{
        AVTALE,
        STILLING,
        TILTAK,
        IA,
        MULIGHET,
        HENVENDELSE,
        MOTE,
        KOMMUNIKASJON,
        FORMIDLING
    };

    public static final Map<String, String> HISTORY_LABELS = new Map<String, String>{
        AVTALE => 'Avtale',
        STILLING => 'Stilling',
        TILTAK => 'Tiltak',
        IA => 'IA-samarbeid',
        MULIGHET => 'Mulighet',
        HENVENDELSE => 'Henvendelse',
        MOTE => 'Møte/oppgave',
        KOMMUNIKASJON => 'Telefon/e-post/SMS',
        FORMIDLING => 'Formidling/kandidat/kampanje'
    };

    public static final Map<String, String> COMMUNICATION_TYPE_LABELS = new Map<String, String>{
        'Call' => 'telefon',
        'Email' => 'e-post',
        'SMS' => 'SMS'
    };
    public static final Set<String> COMMUNICATION_TASK_TYPES = COMMUNICATION_TYPE_LABELS.keySet();
    public static final Set<String> CAMPAIGN_MEMBER_ACTIVITY_STATUSES = new Set<String>{
        'Sendt informasjon',
        'Interessert',
        'Inngått avtale',
        'Gjennomført',
        'Besvart'
    };

    // Filters for ongoing rows mirror BadgeConfigProvider so the summary and the badges show the same data.
    private static final Map<String, Map<String, String>> ONGOING_CONFIG = new Map<String, Map<String, String>>{
        AVTALE => new Map<String, String>{
            'label' => 'Avtaler',
            'helpText' => 'Godkjente arbeidsgiveravtaler som er gyldige i dag. IA-avtaler vises som IA-samarbeid.',
            'icon' => 'custom:custom18',
            'objectApiName' => 'Contract__c',
            'lookupField' => 'TAG_Account__c',
            'queryFilter' => 'RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\'' +
            ' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Category__c != \'IA-avtale\'',
            'detailFields' => 'TAG_Category__c, TAG_Type_Partner__c, TAG_EndDate__c',
            'orderBy' => 'TAG_EndDate__c DESC',
            'columns' => 'TAG_Link__c, TAG_Category__c, TAG_Status__c, TAG_StartDate__c, TAG_EndDate__c, TAG_InternalContact__r.Name'
        },
        STILLING => new Map<String, String>{
            'label' => 'Aktive direktemeldte stillinger',
            'helpText' => 'Aktive stillinger som er direktemeldt til Nav. Offentlig utlyste stillinger er ikke med.',
            'icon' => 'custom:custom27',
            'objectApiName' => 'JobPosting__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'ACTIVE\' AND Source__c = \'DIR\'',
            'detailFields' => 'Title__c, Expires__c',
            'orderBy' => 'Expires__c ASC NULLS LAST',
            'columns' => 'TAG_Link__c, EngagementType__c, Extent__c, WorkplaceCity__c, Expires__c'
        },
        TILTAK => new Map<String, String>{
            'label' => 'Aktive tiltak',
            'helpText' => 'Tiltak som gjennomføres, registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.',
            'icon' => 'custom:custom60',
            'objectApiName' => 'Workfare__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'GJENNOMFØRES\'',
            'detailFields' => 'Type__c',
            'orderBy' => 'EndDate__c ASC NULLS LAST',
            'columns' => 'Name, Type__c, Status__c, StartDate__c, EndDate__c'
        },
        IA => new Map<String, String>{
            'label' => 'Pågående IA-samarbeid',
            'helpText' => 'Aktive IA-samarbeid der IA-saken er under arbeid.',
            'icon' => 'custom:custom37',
            'objectApiName' => 'IACooperation__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'AKTIV\' AND (IACase__r.CaseStatus__c IN (\'NY\', \'VURDERES\', \'KONTAKTES\', \'KARTLEGGES\', \'VURDERT\', \'AKTIV\', \'VI_BISTÅR\'))',
            'detailFields' => 'Type_IA_Cooperation__c, StartDate__c',
            'orderBy' => 'StartDate__c DESC NULLS LAST',
            'columns' => 'Name, Status__c, StartDate__c, EndDate__c'
        },
        MULIGHET => new Map<String, String>{
            'label' => 'Åpne muligheter',
            'helpText' => 'Muligheter som ikke er avsluttet.',
            'icon' => 'custom:custom14',
            'objectApiName' => 'CustomOpportunity__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'InclusionStage__c != \'Avsluttet\'',
            'detailFields' => 'InquiryCategory__c',
            'orderBy' => 'CreatedDate DESC',
            'columns' => 'TAG_Link__c, InclusionStage__c, InquiryCategory__c, TAG_Age__c, TYPEOF Owner WHEN User THEN Name WHEN Group THEN Name END'
        },
        HENVENDELSE => new Map<String, String>{
            'label' => 'Åpne henvendelser',
            'helpText' => 'Henvendelser med status Ny henvendelse, Under arbeid eller Følges opp.',
            'icon' => 'custom:custom28',
            'objectApiName' => 'EmployerInquiry__c',
            'lookupField' => 'TAG_Account__c',
            'queryFilter' => 'TAG_Status__c IN (\'Ny henvendelse\', \'Under arbeid\', \'Følges opp\')',
            'detailFields' => 'TAG_Status__c, CreatedDate',
            'orderBy' => 'CreatedDate DESC',
            'columns' => 'Name, TAG_Status__c, TAG_Theme__c, TAG_DueDate__c, CreatedDate, TYPEOF Owner WHEN User THEN Name WHEN Group THEN Name END'
        },
        PLANLAGT => new Map<String, String>{
            'label' => 'Planlagt møte/oppgave',
            'helpText' => 'Åpne oppgaver med frist i dag eller senere og kommende møter.',
            'icon' => 'standard:event'
        },
        NAVKONTAKT => new Map<String, String>{
            'label' => 'Kontaktpersoner i Nav',
            'helpText' => 'Registrerte kontaktpersoner i Nav for arbeidsgiveren.',
            'icon' => 'standard:team_member'
        }
    };

    public static Map<String, String> getConfig(String key) {
        if (String.isBlank(key) || !ONGOING_CONFIG.containsKey(key)) {
            throw new AccountSummaryConfigException('Unknown summary key: ' + key);
        }
        return ONGOING_CONFIG.get(key);
    }

    public class AccountSummaryConfigException extends Exception {
    }
}
