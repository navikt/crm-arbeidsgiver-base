import { LightningElement, api } from 'lwc';
import Toast from 'lightning/toast';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/EmployerInquiry__c.Id';
import OWNER_FIELD from '@salesforce/schema/EmployerInquiry__c.OwnerId';

import STATUS_FIELD from '@salesforce/schema/EmployerInquiry__c.TAG_Status__c';
import currentUserId from '@salesforce/user/Id';

const WORKING_STATUS = 'Følges opp';

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

            Toast.show({
                label: 'Henvendelsen er nå tildelt deg',
                variant: 'success'
            });
            this.dispatchEvent(new CustomEvent('success'));
        } catch (error) {
            console.error('Error in inquiryAssignmentToUser:', error);
            Toast.show({
                label: 'Kunne ikke tildele henvendelse',
                message: this.translateErrorMessage(error),
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
        await updateRecord(recordInput);
    }

    translateErrorMessage(error) {
        if (error.status === 401) {
            return 'Økten din har utløpt.';
        }
        if (error.status === 403) {
            return 'Du har ikke tilgang til å endre eier på henvendelsen.';
        }
        if (error.status === 404) {
            return 'Henvendelsen ble ikke funnet. Den kan ha blitt slettet eller du har kanskje mistet tilgang til den.';
        }

        return error?.body?.message || error?.message || 'En ukjent feil oppstod';
    }
}
