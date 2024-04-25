import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktAccountOversikt extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Account', { type: 'Oversikt' });
    }
}