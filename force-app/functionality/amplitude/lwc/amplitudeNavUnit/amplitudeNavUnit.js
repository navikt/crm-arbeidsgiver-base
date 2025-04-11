import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';


export default class AmplitudeNavUnit extends LightningElement {
    renderedCallback() {
            this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
            publishToAmplitude(this.appName, { type: 'Nav-enhet - Relatert' });    
        }
}