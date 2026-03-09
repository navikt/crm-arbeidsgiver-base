import { LightningElement, api } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import assignToCurrentUser from '@salesforce/apex/InquiryAssignmentController.assignToCurrentUser';

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
            console.log('Assigning record', this.recordId, 'to current user');
            await assignToCurrentUser({ recordId: this.recordId });
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error in inquiryAssignmentToUser:', error);
            this.dispatchEvent(new CustomEvent('error'));
        } finally {
            this.isExecuting = false;
        }
    }
}
