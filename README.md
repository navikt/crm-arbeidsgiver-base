# Tag Salesforce

Nav bruker scratchorgs og "DX" på utvikling av funksjonalitet i Salesforce, dette vil legge alle endringer i git og under versjonskontroll.

## Komme i gang
1. Du trenger en "dx" bruker denne får du ved å ta kontakt med #crm-plattform-team på slack. 
2. Installer kommandolinjeverktøyet til Salesforce enkleste måten å gjøre dette på er gjennom NPM: `npm install sfdx-cli --global`
3. Du kloner dette repoet `git clone https://github.com/navikt/tag-salesforce-shared`
4. Lag en ny branch `git checkout master;git pull --rebase; git checkout -b mitt_branch_navn`
5. `sfdx force:auth:web:login -d -a NavProd`
6. Opprett ny Scratch-org `sfdx force:org:create -f config\project-scratch-def.json --setalias mitt_branch_navn --durationdays 7 --setdefaultusername --json --loglevel fatal
7. Installer `sfdx force:package:install --package 04t2o000001MxM6AAK  -k navcrm`
8. Installer `sfdx force:package:install --package 04t2o000001MxMBAA0 -k navcrm`

## Utvikling
Utvikling foregår i hovedsak med å bruker kommandoene:
* `sfdx force:org:open` for å åpne instansen(salesforce applikasjonen din).
* `sfdx force:source:pull` for å hente endringer som du gjør i konfigurasjon i applikasjonen online.
* `sfdx force:source:push` for å publisere endringer du gjør i kode lokalt til applikasjonen online.

### Annet

## Closed source
Grunnen til at vi har valg å lukke kildekoden er... (her må dere fylle inn John og co)


For spørsmål om denne applikasjonen #tag-crm på slack.

