import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/EmployerInquiry__c.Id';
import OWNER_FIELD from '@salesforce/schema/EmployerInquiry__c.OwnerId';
import Toast from 'lightning/toast';
import getQueueIdForInquiry from '@salesforce/apex/InquiryAssignmentController.getQueueIdForInquiry';
import STATUS_FIELD from '@salesforce/schema/EmployerInquiry__c.TAG_Status__c';
const WORKING_STATUS = 'Ny henvendelse';

export default class InquiryUnassignment extends LightningElement {
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
            const newOwnerId = await getQueueIdForInquiry({ recordId: this.recordId });

            await this.updateRecordOwner(this.recordId, newOwnerId);
            Toast.show({
                label: 'Oppdatering vellykket',
                message: 'Henvendelsen er nå fjernet fra deg og lagt tilbake i køen for tildeling.',
                variant: 'success'
            });
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error in InquiryUnassignment:', error);
            Toast.show({
                label: 'Kunne ikke oppdatere henvendelsen',
                message: error?.body?.message || error?.message || 'En ukjent feil oppstod',
                variant: 'error'
            });
            this.dispatchEvent(new CustomEvent('error'));
        } finally {
            this.isExecuting = false;
        }
    }

    async updateRecordOwner(recordId, newOwnerId) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[OWNER_FIELD.fieldApiName] = newOwnerId;
        fields[STATUS_FIELD.fieldApiName] = WORKING_STATUS;

        const recordInput = { fields };
        console.log('Updating record with input:', recordInput);
        await updateRecord(recordInput);
    }
}
