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