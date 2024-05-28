import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktOpportunityDetaljer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Custom Opportunity', { type: 'Detaljer' });
    }
}