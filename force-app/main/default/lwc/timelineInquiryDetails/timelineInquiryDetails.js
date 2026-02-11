import { LightningElement, api } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';

export default class TimelineInquiryDetails extends LightningElement {
    @api recordId;
    @api logEvent;

    sObjectType = 'TAG_Inquiry__c';

    /*
    Not needed when using lightning-record-form, but can be used for custom rendering if needed
    error;
    fieldArray = [];
    @wire(getRecord, { recordId: '$recordId', layoutTypes: 'Compact', modes: 'View' })
    wiredRecord({ error, data }) {
        console.log('Calling getRecord with recordId:', this.recordId);
        if (data) {
            this.sObjectType = data.apiName;
            this.fieldArray = Object.keys(data.fields).map((key) => ({
                key: key,
                value: data.fields[key].value,
                displayValue: data.fields[key].displayValue
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Kunne ikke laste data';
            console.error('Error loading record:', error);
        }
    }*/
}
