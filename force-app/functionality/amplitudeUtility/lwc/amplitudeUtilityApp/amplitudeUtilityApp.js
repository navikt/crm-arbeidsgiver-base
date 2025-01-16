import { LightningElement, api } from 'lwc';

export default class AmplitudeUtilityApp extends LightningElement {
    @api appName; // App name passed from App Builder

    connectedCallback() {
        if (this.appName) {
            // Save the app name in localStorage
            localStorage.setItem('currentAppName', this.appName);
        }
    }
}