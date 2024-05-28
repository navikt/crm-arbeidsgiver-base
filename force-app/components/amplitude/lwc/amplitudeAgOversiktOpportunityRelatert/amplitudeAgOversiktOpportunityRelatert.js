import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktOpportunityRelatert extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Custom Opportunity', { type: 'Relatert' });
    }
}