import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktIADeliveryDetaljer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-IA Delivery', { type: 'Detaljer' });
    }
}