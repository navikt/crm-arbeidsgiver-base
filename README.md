# crm-arbeidsgiver-base

[![Build](https://github.com/navikt/crm-arbeidsgiver-base/workflows/master/badge.svg)](https://github.com/navikt/crm-arbeidsgiver-base/actions?query=workflow%3ABuild)
[![GitHub version](https://badgen.net/github/release/navikt/crm-arbeidsgiver-base/stable)](https://github.com/navikt/crm-arbeidsgiver-base)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/crm-arbeidsgiver-base/blob/master/LICENSE)
[![codecov](https://codecov.io/gh/navikt/crm-arbeidsgiver-base/branch/master/graph/badge.svg)](https://codecov.io/gh/navikt/crm-arbeidsgiver-base)

Denne pakken inneholder funksjonalitet og tilgangsstyring på arbeidsgiver-nivået. Blant annet:

- Permitteringer / masseoppsigelser
- Kontaktskjema for arbeidsgivere
- Sykefravær
- Listevisninger
- Objekter
- Aktiviteter
- Arbeidsgiver

## Dependencies

Pakken er avhengig av følgende pakker:

* [crm-platform-base](https://github.com/navikt/crm-platform-base) (internal)
* [crm-platform-access-control](https://github.com/navikt/crm-platform-access-control) (internal)


## Komme i gang

1. Salesforce DX-bruker. Kontakt #crm-plattform-team på Slack om du ikke har dette
2. Installer Salesforce DX CLI (SFDX)
	- Last ned fra [Salesforce.com](https://developer.salesforce.com/tools/sfdxcli)
    - Eller benytt npm: `npm install sfdx-cli --global`
3. Klon dette repoet ([GitHub Desktop](https://desktop.github.com) anbefales for ikke-utviklere)
4. Installer [SSDX](https://github.com/navikt/ssdx)
    - Med SSDX kan du lage scratch orger og gjøre deklarative endringer (gjøre endringer i nettleseren på Salesforce, altså ikke-utvikling)
	- **Trenger du ikke verktøy utvikling kan du stoppe her**
5. Installer [VS Code](https://code.visualstudio.com) (anbefalt)
6. Installer [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
7. Installer [AdoptOpenJDK](https://adoptopenjdk.net) (kun versjon 8 eller 11)
8. Åpne VS Code Settings og søk etter `salesforcedx-vscode-apex`
9. Under `Java Home`, legg inn følgende:
    - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home`
    - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-11.0.3.7-hotspot` (merk at versjonsnummer kan endre seg)

## Utvikling

Utvikling foregår i hovedsak på to fronter, i nettleseren i din scratch org og på din maskin i din prefererte IDE. Ved endringer i nettleseren på din scratch org (som lever i skyen), så må alle endringer pulles til din maskin. Ved endringer av metadata i din IDE, må endringer pushes til din scratch org.

Ved å bruke VS Code som IDE, er det lagt inn konfigurasjon som automatisk pusher endringer av metadata til din scratch org ved lagring. For å pulle endringer fra kan man enten bruke Salesforce DX CLI til å pulle, men også pushe om man ikke ønsker automatisk push. Se under for kommandoer. Man kan også bruke hjelpeverktøyet SSDX (nevnt over) for å pushe, pulle, åpne scratch org-er, slette gamle, blant annet.

* `sfdx force:org:open` for å åpne instansen(salesforce applikasjonen din).
* `sfdx force:source:pull` for å hente endringer som du gjør i konfigurasjon i applikasjonen online.
* `sfdx force:source:push` for å publisere endringer du gjør i kode lokalt til applikasjonen online.

## Annet

For spørsmål om denne applikasjonen, bruk #arbeidsgiver-crm på Slack.
