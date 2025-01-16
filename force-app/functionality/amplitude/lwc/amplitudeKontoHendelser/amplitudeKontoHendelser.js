import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeKontoHendelser extends LightningElement {

    renderedCallback() {
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: 'Konto - Hendelser' });    
    }
}