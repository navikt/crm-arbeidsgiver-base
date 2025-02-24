# Amplitude Integrasjon Dokumentasjon
![Amplitude](https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Amplitude_logo.svg/320px-Amplitude_logo.svg.png)


Følgende dokumentasjon baserer seg både på Team Salesforce Arbeidsgivers implementasjon av Amplitude og på gjenbrukbare komponenter utviklet av Team NKS. For detaljert informasjon om NKS implementasjon og komponeneter, se [dokumentasjonen her](https://confluence.adeo.no/pages/viewpage.action?pageId=579157114).

---

## Gjenbrukte Komponenter

_All kildekode ligger i **crm-platform-reporting**._

- **Static Resource "Amplitude"**  
  Inneholder nødvendige skript fra Amplitude for å kjøre og sende data. Lastes når 
  [amplitudeBackground](https://github.com/navikt/crm-platform-reporting/blob/master/force-app/main/default/aura/amplitudeBackground/amplitudeBackground.cmp) komponenten renderes.

- **Custom Setting "Amplitude Key"**  
  Må opprettes for å hente ut korrekt client API Key for Amplitude-prosjektet. Denne kan knyttes opp mot bruker eller profil i Salesforce. Se også:

   [Amplitude Helper - Apex Class](https://github.com/navikt/crm-platform-reporting/blob/master/force-app/main/default/classes/AmplitudeHelper.cls) 
   
   [Custom Setting Preprod](https://navdialog--preprod.sandbox.my.salesforce-setup.com/lightning/setup/CustomSettings/page?address=%2Fsetup%2Fui%2FlistCustomSettingsData.apexp%3Fid%3Da21)

- **LWC-komponent for Amplitude**  
  Sender data til Amplitude
  [amplitude.js](https://github.com/navikt/crm-platform-reporting/blob/master/force-app/main/default/lwc/amplitude/amplitude.js)

- **LMS (Amplitude LMS)**  
      [LMS](https://github.com/navikt/crm-platform-reporting/blob/master/force-app/main/default/messageChannel/amplitude.messageChannel-meta.xml) Sender data til Aura-komponenten → [amplitudeBackground aura cmp](https://github.com/navikt/crm-platform-reporting/blob/master/force-app/main/default/aura/amplitudeBackground/amplitudeBackground.cmp)

---

## Egendefinerte Komponenter

Vi har utviklet følgende komponenter:

- **Event-komponenter**  
  Ved `renderedCallback` sendes events via `publishToAmplitude`-metoden. Det finnes flere komponenter, én for hver fane i arbeidsgiverkortet.  
  [Se eksempel: amplitudeKontoOversikt](https://github.com/navikt/crm-arbeidsgiver-base/blob/main/force-app/functionality/amplitude/lwc/amplitudeKontoOversikt/amplitudeKontoOversikt.js)

```javascript
import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeKontoOversikt extends LightningElement {

    renderedCallback() {
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: 'Konto - Oversikt' });    
    }
}
```

- **DeviceReader-komponent**  
  Identifiserer om brukeren benytter Desktop, Tablet eller Mobiltelefon for Salesforce.  
  [Se DeviceReader-koden](https://github.com/navikt/crm-arbeidsgiver-base/blob/main/force-app/functionality/amplitudeUtility/lwc/amplitudeDeviceReader/amplitudeDeviceReader.js)

```javascript
import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeKontoOversikt extends LightningElement {

    renderedCallback() {
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: 'Konto - Oversikt' });    
    }
}
```

- **UtilityApp-komponent**  
  Lagrer i nettleserens localStorage navnet på Salesforce-appen (for eksempel «Arbeidsgiver»). Dette sendes via `publishToAmplitude` til Amplitude som eventType. Komponenten bør plasseres i UtilityBar slik at det alltid er lagret korrekt app-navn når brukeren bytter til en annen SF-app.


```javascript
import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeDeviceReader extends LightningElement {

    appName;

    getDeviceType() {
        const width = window.innerWidth;
        
        if (width < 768) {
            return 'Mobile';
        } else if (width <= 1024) {
            return 'Tablet';
        } else {
            return 'Desktop';
        }
    }

    renderedCallback() {
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: this.getDeviceType() });    
    }
}
```


---

## Slik Tar Du Komponentene i Bruk

Før du kan ta i bruk komponentene, må noen felles oppsett være på plass:

1. **Public API Key**  
   Hent API key for dev/prod-miljø fra #amplitude-kanalen på Slack (kun ved første oppsett).

2. **Opprett Custom Settings**  
   Opprett custom settings for bruker/profil i preprod og prod med riktig public API key fra punkt 1.  
   [Opprett Custom Settings](https://navdialog--preprod.sandbox.my.salesforce-setup.com/lightning/setup/CustomSettings/page?address=%2Fsetup%2Fui%2FlistCustomSettingsData.apexp%3Fid%3Da21)

3. **Legg til amplitudeBackground-komponenten**  
   Legg til denne komponenten i UtilityBar for Salesforce-appen.  
   [Se amplitudeBackground Component](https://github.com/navikt/crm-platform-reporting/blob/main/force-app/main/default/aura/amplitudeBackground/amplitudeBackground.cmp)

4. **Legg til amplitudeUtilityApp-komponenten**  
   Plasser denne komponenten i UtilityBar slik at den lagrer Salesforce App-navnet i localStorage.  
   [Se amplitudeUtilityApp Component](https://github.com/navikt/crm-arbeidsgiver-base/blob/main/force-app/functionality/amplitudeUtility/lwc/amplitudeUtilityApp/amplitudeUtilityApp.js)  
   Se også oppsettet i Arbeidsgiver-appen.

5. **Tidslinje**  
   Det er en innebygd funksjon for å måle brukeradferd. Ønsker du å måle adferden på en ny recordPage, aktiverer du målingen i komponenten **"Log events by Amplitude"**.

6. **Standard Salesforce-faner innenfor recordPage**  
   For eksempel, i Arbeidsgiverkortet, lag en ny LWC-komponent, importer `publishToAmplitude` og send custom events i `renderedCallback` via `publishToAmplitude`-metoden.  
   [Se eksempel: amplitudeKontoOversikt](https://github.com/navikt/crm-arbeidsgiver-base/blob/main/force-app/functionality/amplitude/lwc/amplitudeKontoOversikt/amplitudeKontoOversikt.js)



7. **Custom Komponenter (f.eks. Badges)**  
   Importer `publishToAmplitude`-metoden og send events til Amplitude basert på logikk (for eksempel ved klikk eller visning).  
   [Se eksempel: accountBadges](https://github.com/navikt/crm-arbeidsgiver-base/blob/main/force-app/components/accountBadges/lwc/accountBadges/accountBadges.js)
