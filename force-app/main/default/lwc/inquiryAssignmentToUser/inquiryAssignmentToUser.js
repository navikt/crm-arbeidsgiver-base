import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/TAG_Inquiry__c.Id';
import OWNER_FIELD from '@salesforce/schema/TAG_Inquiry__c.OwnerId';
import currentUserId from '@salesforce/user/Id';

export default class InquiryAssignmentToUser extends LightningElement {
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
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        try {
            const newOwnerId = currentUserId;
            await this.updateRecordOwner(this.recordId, newOwnerId);
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error in inquiryAssignmentToUser:', error);
            this.dispatchEvent(new CustomEvent('error'));
        } finally {
            this.isExecuting = false;
        }
    }

    async updateRecordOwner(recordId, newOwnerId) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[OWNER_FIELD.fieldApiName] = newOwnerId;

        const recordInput = { fields };
        await updateRecord(recordInput);
    }
}
