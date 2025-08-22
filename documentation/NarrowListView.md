# NarrowListView Component

## Hva er det?

En tilpasset listevisning som viser Salesforce-data i et kompakt format. Den er spesielt laget for å passe inn i smale kolonner på hjemmesider, i motsetning til Salesforce sin standard listevisning som tar mye plass.

## Hvordan bruker man den?

Som administrator/utvikler:

1. Dra komponenten inn på ønskede sider via Lightning Page Builder
2. Konfigurer følgende innstillinger:
   Grunnleggende oppsett:

-   Object API Name: Hvilket objekt du vil vise (f.eks. "CustomOpportunity\_\_c")
-   List View API Name: Hvilket eksisterende listeview du vil bruke som datakilde
-   Component Heading: Overskrift som vises på komponenten
-   Primary field: Hovedfeltet som vises som klikkbar tittel
-   Secondary field: Valgfritt detaljfelt som vises under
-   Sort by field: Angir hvordan liste sorteres

Visningsinnstillinger:

-   Number of records to display: Hvor mange poster som vises (1-10)
-   Number of records to count: Hvor mange poster som hentes for telling (påvirker ytelse)
-   Object icon: Ikon som vises ved hver post
-   Component Tooltip: Hjelpetekst for komponenten

Avanserte funksjoner:

-   Warning icon conditions: Regler for når varselsikon skal vises
-   Warning tooltip: Tekst som vises når man holder over varselsikonet
-   Show New Record Button: Om "opprett ny"-knapp skal vises

Som sluttbruker:

-   Se listen med poster på hjemmesiden
-   Klikk på titler for å åpne poster
-   Bruk "Se alle" for å gå til full listevisning
-   Opprett nye poster via "ny post"-knappen (hvis aktivert)

## Hvordan fungerer den?

Enkelt forklart:

1. Komponenten bruker et eksisterende Salesforce-listeview som datakilde
2. I stedet for å vise alle kolonner fra listeviewet, velger du kun 1-2 felt som vises kompakt
3. Den henter data automatisk og oppdaterer seg når data endres
4. Viser antall poster i overskriften (f.eks. "Mine muligheter (5)" eller "Mine muligheter (10+)")

Smart varsling:

-   Kan automatisk vise varselsikoner basert på regler du setter opp
-   Eksempel: Vis varsel hvis en sak er eldre enn 1 dag og fortsatt har status "Ny henvendelse"
-   Reglene skrives som: {{TAG_Age__c}} > 1 AND {{InclusionStage__c}} == "Ny henvendelse"

Navigasjon:

-   Klikk på en post → åpner postens detaljside
-   "Se alle" → åpner fullstendig listevisning
-   Støtter også redigering og opprettelse av nye poster

## Hovedflyt

1. Sjekk hvilke felt som må hentes basert på input i komponentet og bygg liste med felt som mates inn i wire service.
2. Wire service `getListRecordsByName` trigges når variablene med $ settes og henter records.

```javascript
// https://developer.salesforce.com/docs/platform/lwc/guide/reference-get-list-records-by-name.html
@wire(getListRecordsByName, {
    objectApiName: '$objectApiName',
    listViewApiName: '$listViewApiName',
    fields: '$queryFields',
    pageSize: '$pageSize',
    ....
})
```

3. Response fra wire service prosesseres og listen med returnerte records mappes til ny struktur:

```javascript
id: record.id,
title: this.getFieldValue(record, this.titleFieldInput),
titleLink: '/lightning/r/' + record.apiName + '/' + record.id + '/view',
detailLine: this.getFieldValue(record, this.detailFieldInput),
showWarning: this.shouldShowWarning(record)
```

4. Liste med strukturerte records vises i html-template

## Tekniske detaljer

### API Properties og input

| Property               | Type    | Required | Description                                                         |
| ---------------------- | ------- | -------- | ------------------------------------------------------------------- |
| `objectApiName`        | String  | ✓        | API-navn for objektet (f.eks. "CustomOpportunity\_\_c")             |
| `listViewApiName`      | String  | ✓        | API-navn for listevisningen                                         |
| `titleFieldInput`      | String  | ✓        | Felt som brukes som tittel og vises som klikkbar lenke til recorden |
| `detailFieldInput`     | String  |          | Sekundært felt for detaljer                                         |
| `sortBy`               | String  |          | Angir sortering.                                                    |
| `warningCriteriaInput` | String  |          | Boolean-uttrykk for varselsikon                                     |
| `warningTextInput`     | String  |          | Tooltip-tekst for varselsikon                                       |
| `titleText`            | String  | ✓        | Overskrift for komponenten                                          |
| `helpText`             | String  |          | Hjelpetekst i tooltip                                               |
| `iconName`             | String  |          | Ikon som vises ved hver record                                      |
| `previewRecords`       | Integer | ✓        | Antall records å vise (1-10)                                        |
| `pageSize`             | Integer | ✓        | Antall records å hente for telling (1-2000)                         |

Siden objekter med autonummer ofte har formelfelt med navn så fjernes eventuellle html tags fra `titleFieldInput`.

`detailFieldInput` støtter lookup-relasjoner (f.eks. `Account__r.Name`)

`pageSize` styrer antall som vises i GUI, mens `previewRecords` hvor høyt antall som vises i header. Er antall records høyere enn `previewRecords` så vises en +.

`warningCriteriaInput` støtter sammenligning av feltverdier med operatorer som `>`, `==`, `!=`, `AND`, `OR` og bruker `{{fieldName}}` syntaks for å referere til feltverdier. Eks. {{TAG_Age__c}} > 1 && {{InclusionStage__c}} == "Ny henvendelse"

### Visning av varselikon

Komponentet tar boolean uttrykk som input for å avgjøre om varsel skal vises.
For å gjøre det enklere å plukke ut feltnavn fra uttrykket skrives de i doble krøllparanteser{{ }}. Feltene plukkes ut før data hentes slik at response fra wire service inneholder feltene som må sjekkes.
Logikk for å evaluere uttrykket:

-   Plukk ut `{{fieldName}}` fra uttrykket og inkluder dem i wire service kallet.
-   For returnerte records, erstatt `{{fieldName}}` i uttrykket med faktiske verdi fra record.
    Eks. om record har TAG_Age**c lik 4, så erstattes `{{TAG_Age**c}} > 1`med`4 > 1`
-   Evaluerer `4 > 1`
