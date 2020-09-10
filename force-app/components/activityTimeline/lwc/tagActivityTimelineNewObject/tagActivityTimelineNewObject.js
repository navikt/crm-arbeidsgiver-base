import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import formFactorPropertyName from '@salesforce/client/formFactor'
import * as helper from "./helper";
import getTimelineObjects from '@salesforce/apex/TAG_ActivityTimelineController.getTimelineObjects';
import newObj from "@salesforce/label/c.ActTime_New";

export default class TagActivityTimelineNewObject extends NavigationMixin(LightningElement) {

    @api recordId;
    @api labels;
    @track sObjectKinds;
    @track error = false;
    newObj = newObj;

    @wire(getTimelineObjects, { recordId: '$recordId' })
    deWire(result) {
        if (result.data) {
            this.sObjectKinds = result.data;
        } else if (result.error) {
            this.error = true;
        }
    };

    createRecord(event) {

        const row = this.sObjectKinds[event.target.dataset.index];

        if (formFactorPropertyName !== 'Small') { // PC AND TABLET

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { objectApiName: row.Activity_Timeline_Child__r.SObjectName__c, actionName: 'new' },
                state: {
                    nooverride: '1',
                    recordTypeId: row.Activity_Timeline_Child__r.CreateableObject_RecordType__c,
                    navigationLocation: 'LOOKUP',
                    useRecordTypeCheck: 1,
                    defaultFieldValues: helper.getFieldValues(row, this.recordId)
                }
            });
        }
    }
}