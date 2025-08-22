# NarrowListView Component

## Hva er det?

En tilpasset listevisning som viser Salesforce-data i et kompakt format. Den er spesielt laget for å passe inn i smale kolonner på hjemmesider, i motsetning til Salesforce sin standard listevisning som tar mye plass.

**Fordeler vs standard listevisning:**

-   ✅ **Kompakt**: Passer i smale kolonner
-   ✅ **Fokusert**: Viser kun de viktigste feltene
-   ✅ **Intelligent varsling**: Fremhever poster som trenger oppmerksomhet
-   ✅ **Rask navigasjon**: Direkte lenker til poster og fullstendig listevisning
-   ⚠️ **Begrenset**: Viser færre felt og poster enn standard listevisning

## Typiske bruksområder

-   Dashboard-widgets på hjemmesider
-   "Mine oppgaver"-oversikter
-   Rask tilgang til viktige poster
-   Områder med begrenset skjermplass

## Hvordan bruker man den?

**Som administrator/utvikler:**

1. Dra komponenten inn på ønskede sider via Lightning Page Builder
2. Konfigurer følgende innstillinger:

**Grunnleggende oppsett:**

-   Object API Name: Hvilket objekt du vil vise (f.eks. "CustomOpportunity\_\_c")
-   List View API Name: Hvilket eksisterende listeview du vil bruke som datakilde
-   Component Heading: Overskrift som vises på komponenten
-   Primary field: Hovedfeltet som vises som klikkbar tittel
-   Secondary field: Valgfritt detaljfelt som vises under hovedfelt. Støtter lookup-relasjoner (f.eks. `Account__r.Name`)
-   Sort by field: Angir hvordan liste sorteres

**Visningsinnstillinger:**

-   Number of records to display: Hvor mange poster som vises (1-10)
-   Number of records to count: Hvor mange poster som hentes for telling (påvirker ytelse)
-   Object icon: Ikon som vises ved hver post
-   Component Tooltip: Hjelpetekst for komponenten

`pageSize` styrer hvor mange poster som hentes for å vise totaltall, mens `previewRecords` styrer hvor mange som faktisk vises. Er antall records høyere enn `pageSize` så vises en +.

**Avanserte funksjoner:**

-   Warning icon conditions: Regler for når varselsikon skal vises
-   Warning tooltip: Tekst som vises når man holder over varselsikonet
-   Show New Record Button: Om "opprett ny"-knapp skal vises

`warningCriteriaInput` støtter sammenligning av feltverdier med operatorer som `>`, `==`, `!=`, `AND`, `OR` og bruker `{{fieldName}}` syntaks for å referere til feltverdier. Eksempel: `{{TAG_Age__c}} > 1 && {{InclusionStage__c}} == "Ny henvendelse"`

**Som sluttbruker:**

-   Se listen med poster på hjemmesiden
-   Klikk på titler for å åpne poster
-   Bruk "Se alle" for å gå til full listevisning
-   Opprett nye poster via "ny post"-knappen (hvis aktivert)

## Hvordan fungerer den?

**Enkelt forklart:**

1. Komponenten bruker et eksisterende Salesforce-listeview som datakilde
2. I stedet for å vise alle kolonner fra listeviewet, velger du kun 1-2 felt som vises kompakt
3. Den henter data automatisk og oppdaterer seg når data endres
4. Viser antall poster i overskriften (f.eks. "Mine muligheter (5)" eller "Mine muligheter (10+)")

**Smart varsling:**

-   Kan automatisk vise varselsikoner basert på regler du setter opp
-   Eksempel: Vis varsel hvis en sak er eldre enn 1 dag og fortsatt har status "Ny henvendelse"
-   Reglene skrives som: `{{TAG_Age__c}} > 1 AND {{InclusionStage__c}} == "Ny henvendelse"`

**Navigasjon:**

-   Klikk på en post → åpner postens detaljside
-   "Se alle" → åpner fullstendig listevisning
-   Støtter også redigering og opprettelse av nye poster

## Tekniske detaljer

### Hovedflyt i narrowListView.js

1. **Input-behandling og evaluering**:

    - `@api` properties (`objectApiName`, `titleFieldInput`, etc.) mottas fra Page Builder.

    * Komponenten analyserer input-parametere og bestemmer hvilke felt som må hentes fra Salesforce basert på tittel-, detalj- og varslingsfelt.
        - `queryFields` bygger liste med nødvendige felt basert på input
        - `sortField` konverterer sorteringsparameter til riktig format
        - `warningFields` ekstraherer feltnavn fra varslingskriterier

2. **Wire adapter trigger**:

-   `getListRecordsByName` kalles automatisk når reactive properties (prefixed med `$`) endres og henter records fra det spesifiserte listeviewet med de nødvendige feltene.
    Komponentet benytter en standard wire adapter for å hente data. Se [lightning/uiListsApi getListRecordsByName](https://developer.salesforce.com/docs/platform/lwc/guide/reference-get-list-records-by-name.html) i Salesforce developer guide for beskrivelse av funksjonen og parametere.

3. **Datamottak i `wiredListViewRecords()`**:

-   Hver record transformeres til en enkel struktur med tittel, detaljlinje, varslingsstatus og navigasjonslenke. Dette gjøres av `createDataItemFromRecord()` som:

    -   Henter tittel via `getFieldValue()`
    -   Henter detaljlinje via `getFieldValue()`
    -   Evaluerer om varselsikon skal vises via `shouldShowWarning()`
    -   Bygger navigasjons-URL

### Mer om visning av varselikon

Komponentet tar boolean uttrykk som input for å avgjøre om varsel skal vises.
For å gjøre det enklere å plukke ut feltnavn fra uttrykket skrives de i doble krøllparanteser{{ }}. Feltene plukkes ut før data hentes slik at response fra wire service inneholder feltene som må sjekkes.
Logikk for å evaluere uttrykket:
For å gjøre det enklere å plukke ut feltnavn fra uttrykket skrives de i doble krøllparanteser `{{ }}`. Feltene plukkes ut før data hentes slik at response fra wire service inneholder feltene som må sjekkes, og når data returneres gjøres enn sammenligning på feltinnhold.

**Logikk for å evaluere uttrykket:**

-   Plukk ut `{{fieldName}}` fra uttrykket og inkluder dem i wire service kallet.
-   For returnerte records, erstatt `{{fieldName}}` i uttrykket med faktiske verdi fra record.
    Eks. om record har TAG_Age**c lik 4, så erstattes `{{TAG_Age**c}} > 1`med`4 > 1`Eks. om record har`TAG_Age**c`lik 4, så erstattes`{{TAG_Age**c}} > 1`med`4 > 1`
-   Evaluerer `4 > 1`
