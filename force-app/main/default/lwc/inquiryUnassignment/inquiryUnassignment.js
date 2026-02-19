import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/TAG_Inquiry__c.Id';
import OWNER_FIELD from '@salesforce/schema/TAG_Inquiry__c.OwnerId';
import QUEUEID_FIELD from '@salesforce/schema/TAG_Inquiry__c.NavUnit__r.CRM_QueueId__c';
const FIELDS = [QUEUEID_FIELD];

export default class InquiryUnassignment extends LightningElement {
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
            this.queueId = null;
        }
    }

    isExecuting = false;
    queueId = null;
    _queueIdResolve = null;

    @api async invoke() {
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        try {
            const newOwnerId = await this.getQueueId();
            await this.updateRecordOwner(this.recordId, newOwnerId);
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error in InquiryUnassignment:', error);
            this.dispatchEvent(new CustomEvent('error'));
        } finally {
            this.isExecuting = false;
        }
    }

    getQueueId() {
        if (this.queueId) {
            return Promise.resolve(this.queueId);
        }
        return new Promise((resolve, reject) => {
            this._queueIdResolve = resolve;
            setTimeout(() => reject(new Error('Timeout waiting for queueId')), 10000);
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(response) {
        if (response.data) {
            this.queueId = response.data.fields.NavUnit__r.value.fields.CRM_QueueId__c.value;
            if (this._queueIdResolve) {
                this._queueIdResolve(this.queueId);
                this._queueIdResolve = null;
            }
        } else if (response.error) {
            console.error('Error retrieving record:', response.error);
        }
    }

    async updateRecordOwner(recordId, newOwnerId) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[OWNER_FIELD.fieldApiName] = newOwnerId;

        const recordInput = { fields };
        console.log('Updating record with input:', recordInput);
        await updateRecord(recordInput);
    }
}
