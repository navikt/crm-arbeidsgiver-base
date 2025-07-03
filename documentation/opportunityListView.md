# OpportunityListView Component

## Oversikt

`opportunityListView` er en Lightning Web Component som viser en tilpasset listevisning for Salesforce-objekter. 
Komponenten er laget for å passe inn i smale kolonner på hjemmesider og tilbyr en mer kompakt visning enn standard listevisningskomponent.

Funksjonen er basert på standard list view komponent. Man velger objekt, hvilket list view som skal vises og antal rader.
I stedet for å vise alle kolonner fra list view så spesifiserer man hvilke felt som skal vises i komponentet.
I tillegg kan man spesifisere kriterier for å markere en linje med varselsymbol.
Komponentet er utviklet for muligheter, men fungerer for andre custom objekter og standard objekter som er tilgjenelige i UI API. 

## Hovedflyt

1) Sjekk hvilke felt som må hentes basert på input i komponentet og bygg liste med felt som mates inn i wire service.
2) Wire service `getListRecordsByName` trigges når variablene med $ settes og henter records.
```javascript
// https://developer.salesforce.com/docs/platform/lwc/guide/reference-get-list-records-by-name.html
@wire(getListRecordsByName, {
    objectApiName: '$objectApiName',
    listViewApiName: '$listViewApiName', 
    fields: '$queryFields',
    pageSize: '$pageSize'
})
```

3) Response fra wire service prosesseres og listen med returnerte records mappes til ny struktur:
```javascript
id: record.id,
title: this.getFieldValue(record, this.titleFieldInput),
titleLink: '/lightning/r/' + record.apiName + '/' + record.id + '/view',
detailLine: this.getFieldValue(record, this.detailFieldInput),
showWarning: this.shouldShowWarning(record)
```
4) Liste med strukturerte records vises i html-template



## API Properties og detaljer

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `objectApiName` | String | ✓ | API-navn for objektet (f.eks. "CustomOpportunity__c") |
| `listViewApiName` | String | ✓ | API-navn for listevisningen |
| `titleFieldInput` | String | ✓ | Felt som brukes som tittel og vises som klikkbar lenke til recorden |
| `detailFieldInput` | String |  | Sekundært felt for detaljer |
| `warningCriteriaInput` | String |  | Boolean-uttrykk for varselsikon |
| `warningTextInput` | String |  | Tooltip-tekst for varselsikon |
| `titleText` | String | ✓ | Overskrift for komponenten |
| `helpText` | String |  | Hjelpetekst i tooltip |
| `iconName` | String |  | Ikon som vises ved hver record |
| `previewRecords` | Integer | ✓ | Antall records å vise (1-10) |
| `pageSize` | Integer | ✓ | Antall records å hente for telling (1-2000) |



Siden objekter med autonummer ofte har formelfelt med navn så fjernes eventuellle html tags fra  `titleFieldInput`.

`detailFieldInput` støtter lookup-relasjoner (f.eks. `Account__r.Name`)

`pageSize` styrer antall som vises i GUI, mens `previewRecords` hvor høyt antall som vises i header. Er antall records høyere enn `previewRecords` så vises en +. 


`warningCriteriaInput` støtter sammenligning av feltverdier med operatorer som `>`, `==`, `!=`, `AND`, `OR` og bruker `{{fieldName}}` syntaks for å referere til feltverdier. Eks. {{TAG_Age__c}} > 1 && {{InclusionStage__c}} == "Ny henvendelse"

### Visning av varselikon
Komponentet tar boolean uttrykk som input for å avgjøre om varsel skal vises. 
For å gjøre det enklere å plukke ut feltnavn fra uttrykket skrives de i doble krøllparanteser{{ }}. Feltene plukkes ut før data hentes slik at response fra wire service inneholder feltene som må sjekkes.
Logikk for å evaluere uttrykket:
- Plukk ut `{{fieldName}}` fra uttrykket og inkluder dem i wire service kallet.
- For returnerte records, erstatt `{{fieldName}}` i uttrykket med faktiske verdi fra record. 
Eks. om record har TAG_Age__c lik 4, så erstattes `{{TAG_Age__c}} > 1` med `4 > 1`
- Evaluerer `4 > 1`



## Utvidelsesmuligheter / Foreslåtte forbedringer

3. **Sortering**: Konfigurerbar sortering av records
5. **Bulk-handlinger**: Støtte for handlinger på flere records samtidig
4. **Internationalization**: Støtte for flere språk

1. **Service Layer**: Ekstrahere API-kall til dedikerte services

Task og Event støttes ikke ennå i UI API, så må bruke Apex for å hente disse.
Undersøkt om man kan bruke detaljer fra list view for å bygge soql query, men list view filter er ikke tilgjengelig i Apex. 
Foreslår å lage et eget komponent for Task og Events tar filter som input i tillegg til input på `opportunityListView`, og ellers er ganske likt. Det ryktes om at støtte i UI API kommer sommeren 2026, så da kan man kan man slå de sammen :) 
