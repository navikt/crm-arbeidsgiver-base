import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktIACaseDetaljer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-IA Case', { type: 'Detaljer' });
    }
}