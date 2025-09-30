# Brukerfeedback-løsning - Oversikt

## Hva er det?

En enkel løsning som lar brukere gi feedback på ulike komponenter/funksjoner i systemet ved å klikke på tommel opp 👍 eller tommel ned 👎.

## Hvordan bruker man det?

Som utvikler/administrator:

1.  Legg til feedback-komponenten på ønskede sider ved å dra den inn i Lightning Page Builder
2.  Konfigurer følgende:
    -   Component Name: Navn på komponenten/funksjonen du vil ha feedback på (påkrevd)
    -   Page: Hvilken side komponenten befinner seg på (valgfritt)
    -   Question: Spørsmålet som vises til brukeren (f.eks. "Var dette nyttig?") (valgfritt)
    -   Thank You Message: Tekst som vises etter stemmegivning for tommel opp (valgfritt)
    -   Follow Up Message: Tekst som vises etter stemmegivning for tommel ned (valgfritt)
    -   Float Right: Om komponenten skal plasseres til høyre (standard: ja)
    
    Tips: "Thank You Message" og "Follow Up Message" kan inneholde link til eksterne sider. Eks. `Fortell oss gjerne mer <a href="https://din_link">her</a>`

Som bruker:

1.  Se spørsmålet/meldingen på siden
2.  Klikk på 👍 (tommel opp) eller 👎 (tommel ned)
3.  Se takkemeldingen
4.  Komponenten husker at du har stemt og viser ikke spørsmålet igjen

## Lagrer den data om brukere?

Nei, løsningen lagrer IKKE personopplysninger eller brukeridentifikasjon.

Data som lagres:

-   Hvilken komponent/funksjon som ble vurdert
-   Hvilken side det skjedde på
-   Spørsmålet som ble stilt
-   Stemmen (1 for tommel opp, -1 for tommel ned)
-   Tidspunkt for feedback

Løsningen husker i nettleseren at en bruker har stemt for å unngå gjentatte spørsmål, men denne informasjonen lagres kun lokalt og sendes ikke til serveren.

## Hvordan ser man svar?

Feedback blir lagret i Salesforce-objektet "In App Feedback" og kan sees på følgende måter:

1. Salesforce Reports: Lag rapporter basert på In App Feedback-objektet
2. Salesforce Dashboard: Visualiser feedback-data i dashboards

## Tilgangsstyring:

-   Vanlige brukere: For å gi feedback må bruker ha tilgang til TAG_FeedbackHandler Apex class og Arbeidsgiver_Se_sp_rsm_l_fra_In_App_Feedback Custom permission
-   Administratorer: For å se feedback må man ha tilgang til InAppFeedback__c objekt og felt.

## Teknisk arkitektur (forenklet)

Løsningen består av:
-   Et Lightning Web Component som viser feedback-knappene
-   En custom permission som styrer om Lightning Web Component skal vises
-   En Apex-klasse som håndterer stemmegivning
-   Platform Events for asynkron databehandling
-   En Flow som lager feedback-records
-   Et custom object for lagring av feedback-data

## Testing: Resette feedback
-   Åpne DevTools og finn Local Storage (Google "how to view localStorage in [browser name]" for å finne hvordan).
-   Under Local Storage, velg domene for Salesforce-miljøet.
-   Finn nøkkelen "LSKey[c]requestUserFeedback" i listen.
-   Slett: Høyreklikk på raden og velg Delete.

 
