import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktAccountRekruttering extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Account', { type: 'Rekruttering' });
    }
}