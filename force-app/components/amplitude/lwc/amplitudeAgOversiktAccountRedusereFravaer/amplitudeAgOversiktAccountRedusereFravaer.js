import { LightningElement } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

export default class AmplitudeAgOversiktAccountRedusereFravaer extends LightningElement {
    renderedCallback() {
        publishToAmplitude('AgOversikt-Account', { type: 'Redusere Fravær' });
    }
}