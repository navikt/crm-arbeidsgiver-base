public with sharing class BadgeConfigProvider {
    public static Map<String, String> getBadgeConfig(String badgeType) {
        if (!BADGE_CONFIG.containsKey(badgeType)) {
            throw new BadgeConfigProviderException(
                'Badge "' + badgeType + '" was requested, but not found in BadgeFactory.'
            );
        }
        return BADGE_CONFIG.get(badgeType);
    }

    public static List<String> getAvailableBadgeTypes() {
        return new List<String>(BADGE_CONFIG.keySet());
    }

    // Centralized badge config for query, icon, help text etc.
    private static final Map<String, Map<String, String>> BADGE_CONFIG = new Map<String, Map<String, String>>{
        'muligheter' => new Map<String, String>{
            'badgeKey' => 'muligheter',
            'labelTemplate' => 'Muligheter({0})',
            'listTitle' => 'Muligheter',
            'helpText' => 'Antall åpne muligheter. Inkluderer alle muligheter for denne bedriften i stegene "Ny henvendelse", "Utforskes" og "Åpen for kandidater".',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'Muligheter',
            'icon' => 'custom:custom14',
            'columns' => 'Name,TAG_Link__c, Source__c, InclusionStage__c,TYPEOF Owner WHEN User THEN Alias WHEN Group THEN Name END,TAG_Age__c,Position_in_Rekrutteringsbistand__c',
            'objectApiName' => 'CustomOpportunity__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'InclusionStage__c != \'Avsluttet\''
        },
        'stillinger' => new Map<String, String>{
            'badgeKey' => 'stillinger',
            'labelTemplate' => 'Stillinger({0})',
            'listTitle' => 'Stillinger',
            'helpText' => 'Antall aktive offentlige utlyste- og direktemeldte stillinger.',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'Stillinger',
            'icon' => 'custom:custom27',
            'columns' => 'Name,TAG_Link__c, EngagementType__c,Extent__c,Expires__c, Link_to_position__c',
            'objectApiName' => 'JobPosting__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'ACTIVE\''
        },
        'tiltak' => new Map<String, String>{
            'badgeKey' => 'tiltak',
            'labelTemplate' => 'Tiltak({0})',
            'listTitle' => 'Tiltak',
            'helpText' => 'Antall aktive tiltak registrert i Tiltaksgjennomføring og Ekspertbistand fra Arena.',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'Tiltak',
            'icon' => 'custom:custom60',
            'columns' => 'Name, Type__c, Status__c, StartDate__c, EndDate__c',
            'objectApiName' => 'Workfare__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'GJENNOMFØRES\''
        },
        'ia-samarbeid' => new Map<String, String>{
            'badgeKey' => 'ia-samarbeid',
            'labelTemplate' => 'IA-samarbeid({0})',
            'listTitle' => 'IA-samarbeid',
            'helpText' => 'Antall aktive IA-samarbeid for denne bedriften.',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'IA-samarbeid',
            'icon' => 'standard:form',
            'columns' => 'Name,Status__c, StartDate__c,EndDate__c',
            'objectApiName' => 'IACooperation__c',
            'lookupField' => 'Account__c',
            'queryFilter' => 'Status__c = \'AKTIV\' AND (IACase__r.CaseStatus__c IN (\'NY\', \'VURDERES\', \'KONTAKTES\', \'KARTLEGGES\', \'VI_BISTÅR\'))'
        },
        'strategisk_partner' => new Map<String, String>{
            'badgeKey' => 'strategisk_partner',
            'labelTemplate' => 'Strategisk partner',
            'listTitle' => 'Strategisk partner',
            'helpText' => 'Denne bedriftens partnerstatus basert på aktive avtaler.',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'Partnerstatus',
            'icon' => 'custom:form',
            'columns' => 'Name,TAG_Link__c, TAG_Status__c,TAG_StartDate__c,TAG_EndDate__c,TAG_Category__c',
            'objectApiName' => 'Contract__c',
            'lookupField' => 'TAG_Account__c',
            'queryFilter' => 'RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Category__c=\'Strategisk partner\''
        },
        'markedssamarbeid' => new Map<String, String>{
            'badgeKey' => 'markedssamarbeid',
            'labelTemplate' => 'Markedssamarbeid',
            'listTitle' => 'Markedssamarbeid',
            'helpText' => 'Bedriften har avtale med tilsvarende kategori.',
            'urlTemplate' => '/lightning/cmp/c__badgePage?c__id={0}&c__badge={1}',
            'badgeType' => 'Samarbeidsavtale',
            'icon' => 'standard:form',
            'columns' => 'Name,TAG_Link__c, TAG_Status__c,TAG_StartDate__c,TAG_EndDate__c,TAG_Category__c',
            'objectApiName' => 'Contract__c',
            'lookupField' => 'TAG_Account__c',
            'queryFilter' => 'RecordType.DeveloperName = \'EmployerAgreement\' AND TAG_Status__c = \'Godkjent\' AND TAG_EndDate__c > TODAY AND TAG_StartDate__c <= TODAY AND TAG_Category__c=\'Markedssamarbeid\''
        }
        // Add more badge configs as needed
    };

    public class BadgeConfigProviderException extends Exception {
    }
}
