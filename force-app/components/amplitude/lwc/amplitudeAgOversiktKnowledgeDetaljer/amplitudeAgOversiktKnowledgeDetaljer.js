import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktKnowledgeDetaljer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Knowledge', { type: 'Detaljer' });
    }
}