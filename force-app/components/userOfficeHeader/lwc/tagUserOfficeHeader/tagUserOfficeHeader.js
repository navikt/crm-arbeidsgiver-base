import { LightningElement, api, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import COMPANY_NAME_FIELD from '@salesforce/schema/User.CompanyName';

const FIELDS = [FIRST_NAME_FIELD, LAST_NAME_FIELD, COMPANY_NAME_FIELD];

export default class TagUserOfficeHeader extends LightningElement {
    @api showWelcomeMessage;

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord;

    get fullName() {
        const data = this.userRecord.data;
        if (data) {
            return `${data.fields.FirstName.value} ${data.fields.LastName.value}`;
        }
        return '';
    }

    get companyName() {
        const data = this.userRecord.data;
        return data ? data.fields.CompanyName.value : '';
    }
}
