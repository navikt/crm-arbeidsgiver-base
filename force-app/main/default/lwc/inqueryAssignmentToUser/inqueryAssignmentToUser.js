import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/TAG_Inquiry__c.Id';
import OWNER_FIELD from '@salesforce/schema/TAG_Inquiry__c.OwnerId';
import currentUserId from '@salesforce/user/Id';

export default class InqueryAssignmentToUser extends LightningElement {
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    isExecuting = false;

    @api async invoke() {
        console.log('Invoking inqueryAssignmentToUser for recordId:', this.recordId);
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        await this.sleep(2000);
        this.isExecuting = false;

        const newOwnerId = currentUserId; // Get the current user's ID
        this.updateRecordOwner(this.recordId, newOwnerId);
        this.dispatchEvent(new CustomEvent('success'));
    }

    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    updateRecordOwner(recordId, newOwnerId) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[OWNER_FIELD.fieldApiName] = newOwnerId;

        const recordInput = { fields };
        try {
            updateRecord(recordInput);
            console.log('Record owner updated successfully');
        } catch (error) {
            console.error('Error updating record owner:', error);
        }
    }
}
