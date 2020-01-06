# Tag Salesforce

Nav bruker Salesforce DX og scratch orgs på utvikling av funksjonalitet i Salesforce, som vil legge alle endringer i git og under versjonskontroll.

## Komme i gang

1. Du trenger en DX-bruker for å kunne lage scratch org-er. Denne får du ved å ta kontakt med #crm-plattform-team på Slack.
2. Installer kommandolinjeverktøyet til Salesforce, DX CLI. Enkleste måten å gjøre dette på er gjennom npm: `npm install sfdx-cli --global`
3. Du kloner dette repoet `git clone https://github.com/navikt/tag-salesforce-shared`
4. Lag en ny branch `git checkout master;git pull --rebase; git checkout -b mitt_branch_navn`
5. Kjør `install.command` på macOS eller `install.cmd` på Windows
6. Kjør `run.command` på macOS eller `run.cmd` på Windows
7. Åpne `ALL ORG COMMANDS` og så `LOGIN to org`, logg inn med din DX-bruker
8. Lag en scratch org med `CREATE Scratch Org` (denne kommandoen lager en scratch org, pusher all metadata og installerer alle nødvendige pakker)

## Utvikling

Utvikling foregår i hovedsak på to fronter, i nettleseren i din scratch org og på din maskin i din prefererte IDE. Ved endringer i nettleseren på din scratch org (som lever i skyen) på alle endringer pulles til din maskin. Ved endringer av metadata i din IDE, må endringer pushes til din scratch org.

Ved å bruke VS Code som IDE, er det lagt inn konfigurasjon som automatisk pusher endringer av metadata til din scratch org ved lagring. For å pulle endringer fra kan man enten bruke Salesforce DX CLI til å pulle, men også pushe om man ikke ønsker automatisk push. Se under for kommandoer. Man kan også bruke hjelpeverktøyet SSDX (nevnt over) for å pushe, pulle, åpne scratch org-er, slette gamle, blant annet.

* `sfdx force:org:open` for å åpne instansen(salesforce applikasjonen din).
* `sfdx force:source:pull` for å hente endringer som du gjør i konfigurasjon i applikasjonen online.
* `sfdx force:source:push` for å publisere endringer du gjør i kode lokalt til applikasjonen online.

## Annet

For spørsmål om denne applikasjonen, bruk #tag-crm på Slack.
