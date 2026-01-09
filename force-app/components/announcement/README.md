# Announcement Component

Announcement-komponenten er en Lightning Web Component som viser kunngjøringer og meldinger til brukere i Salesforce Arbeidsgiver. Komponenten henter data fra `TAG_Announcement__c` objektet og viser aktive innlegg i en oversiktlig liste.

**Eksempel på bruk**

```html
<c-announcement
    input-title="Viktige meldinger"
    input-help-text="Her finner du viktige oppdateringer"
    input-number-of-records-to-show="3"
></c-announcement>
```

## Hovedfunksjoner

- **Visning av kunngjøringer**: Henter og viser aktive kunngjøringer fra en liste-visning
- **Dynamisk innholdshåndtering**: Forkorter lange tekster automatisk (maks 1000 tegn)
- **Lenker**: Støtter lenker til eksterne ressurser (f.eks. Teams)
- **Admin-funksjoner**: Brukere med tillatelsen `Arbeidsgiver_Announcements_View_admin_options` kan:
    - Opprette nye kunngjøringer
    - Redigere eksisterende kunngjøringer
    - Åpne listevisning for administrasjon

## Teknisk informasjon

- Bruker listevisningen `Teams_Alle_innlegg`
- Filtrerer automatisk på aktive innlegg (`TAG_Active__c = true`)
- Sorterer etter publiseringsdato (nyeste først)
- Knapper for aAdministrasjon krever custom permission `Arbeidsgiver_Announcements_View_admin_options`, men faktisk CRUD-tilganger til objektet styres av profil og permissionset.

### Egenskaper

| Egenskap                     | Type    | Standard                                    | Beskrivelse                                 |
| ---------------------------- | ------- | ------------------------------------------- | ------------------------------------------- |
| `inputTitle`                 | String  | "Bli med å påvirke Salesforce Arbeidsgiver" | Tittel som vises øverst i komponenten       |
| `inputHelpText`              | String  | ""                                          | Hjelpetekst som vises ved siden av tittelen |
| `inputNumberOfRecordsToShow` | Integer | 2                                           | Antall kunngjøringer som vises (1-10)       |
