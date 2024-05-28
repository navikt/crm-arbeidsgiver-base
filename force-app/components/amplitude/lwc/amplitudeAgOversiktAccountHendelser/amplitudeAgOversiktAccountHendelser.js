import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktAccountHendelser extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Account', { type: 'Hendelser' });
    }
}