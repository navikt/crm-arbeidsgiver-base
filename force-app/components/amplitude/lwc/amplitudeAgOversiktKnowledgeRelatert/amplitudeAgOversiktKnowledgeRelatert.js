import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktKnowledgeRelatert extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Knowledge', { type: 'Relatert' });
    }
}