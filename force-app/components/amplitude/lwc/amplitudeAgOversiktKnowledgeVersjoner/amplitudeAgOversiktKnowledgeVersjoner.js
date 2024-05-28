import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';


export default class AmplitudeAgOversiktKnowledgeVersjoner extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Knowledge', { type: 'Versjoner' });
    }
}