import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import * as helper from './helper';
import getTimelineObjects from '@salesforce/apex/Timeline_Controller.getTimelineObjects';
export default class GenericLogActivities extends NavigationMixin(LightningElement) {
    @api configIdProperty;
    showCreateRecords = true;
    isGrouped = false;
    @api recordIdProperty;
    containsMacros;
    @track sObjects;

    @api get recordId() {
        console.log('recordIdProperty: ' + this.recordIdProperty);
        return this.recordIdProperty;
    }
    @api get configId() {
        console.log('configIdProperty: ' + this.configIdProperty);
        return this.configIdProperty;
    }

    @wire(getTimelineObjects, { recordId: '$recordId', configId: '$configId' })
    deWire(result) {
        if (result.data) {
            this.sObjects = result.data;

            for (let i = 0; i < result.data.length; i++) {
                const elem = result.data[i];
                if (elem.IsMacro__c) {
                    this.containsMacros = true;
                }
            }
        } else if (result.error) {
            console.log('error: ' + JSON.stringify(result.error));
        }
    }

    createRecord(event) {
        const row = this.sObjects[event.target.dataset.index];
        const override = this.sObjects[event.target.dataset.index].CreateableObject_NoOverride__c == false ? '0' : '1'; // == false to fallback to true if null

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: row.Timeline_Child__r.SObjectName__c,
                actionName: 'new'
            },
            state: {
                nooverride: override,
                recordTypeId: row.Timeline_Child__r.CreateableObject_RecordType__c,
                navigationLocation: 'RECORD_DETAIL',
                useRecordTypeCheck: 1,
                defaultFieldValues: helper.getFieldValues(row, this.recordId),
                backgroundContext: '/lightning/r/' + this.recordId + '/view'
            }
        });
    }
}
