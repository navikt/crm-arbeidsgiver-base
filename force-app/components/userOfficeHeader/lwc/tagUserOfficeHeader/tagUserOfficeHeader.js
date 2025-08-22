import { LightningElement, api, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import COMPANY_NAME_FIELD from '@salesforce/schema/User.CompanyName';
import REGION_NAME_FIELD from '@salesforce/schema/User.Region__c';

const FIELDS = [FIRST_NAME_FIELD, LAST_NAME_FIELD, COMPANY_NAME_FIELD, REGION_NAME_FIELD];

export default class TagUserOfficeHeader extends LightningElement {
    @api headerUserAffiliation;
    @api showWelcomeMessage;

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord;

    get isUser() {
        return this.headerUserAffiliation === 'User';
    }

    get isNavOffice() {
        return this.headerUserAffiliation === 'Nav office';
    }

    get isNavRegion() {
        return this.headerUserAffiliation === 'Nav region';
    }

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

    get regionName() {
        const data = this.userRecord.data;
        return data ? data.fields.Region__c.value : '';
    }
}
