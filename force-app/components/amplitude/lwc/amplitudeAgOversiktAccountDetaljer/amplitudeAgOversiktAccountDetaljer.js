import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktAccountDetaljer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Account', { type: 'Detaljer' });
    }
}