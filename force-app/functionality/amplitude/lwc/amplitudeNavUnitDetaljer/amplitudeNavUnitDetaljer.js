import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';


export default class AmplitudeNavUnitDetaljer extends LightningElement {
    renderedCallback() {
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: 'Nav-enhet - Detaljer' });    
    }
}