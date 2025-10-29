import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ORG_FORMULA_FIELD from '@salesforce/schema/Account.OrganizationNumberFormula__c';
import MAIN_INDUSTRY_FIELD from '@salesforce/schema/Account.CRM_MainIndustry__c';
import REGISTRATION_YEAR_FIELD from '@salesforce/schema/Account.CRM_RegistrationYear__c';
import EMPLOYEES_FORMULA_FIELD from '@salesforce/schema/Account.CRM_NumberOfEmployeesFormula__c';
import PARENT_ID from '@salesforce/schema/Account.ParentId';
import PARENT_NAME_FIELD from '@salesforce/schema/Account.Parent.Name';

const ACCOUNT_FIELDS = [
    ORG_FORMULA_FIELD,
    MAIN_INDUSTRY_FIELD,
    REGISTRATION_YEAR_FIELD,
    EMPLOYEES_FORMULA_FIELD,
    PARENT_ID,
    PARENT_NAME_FIELD
];

/**
 * Component for displaying account information in a compact layout format
 * Similar to the standard Salesforce Account Compact Layout
 */
export default class AccountCompactView extends NavigationMixin(LightningElement) {
    @api recordId;
    objectInfo;
    accountData;
    error;
    isLoading = false;
    PARENT_ACCOUNT_LABEL_NO = 'Overordnet konto'; // Hardcoded value for "Parent Account" since standard label is unavailable in this context

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = 'Kunne ikke laste konto';
            this.accountData = undefined;
            this.isLoading = false;
            console.error('Error loading account:', error);
        }
    }
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

    get name() {
        return this.getFieldData(ACCOUNT_NAME);
    }
    get organisationNumber() {
        return this.getFieldData(ORG_FORMULA_FIELD);
    }

    get mainIndustry() {
        return this.getFieldData(MAIN_INDUSTRY_FIELD);
    }

    get numberOfEmployees() {
        return this.getFieldData(EMPLOYEES_FORMULA_FIELD);
    }

    get registrationYear() {
        return this.getFieldData(REGISTRATION_YEAR_FIELD);
    }

    get accountUrl() {
        return this.recordId ? `/lightning/r/Account/${this.recordId}/view` : '#';
    }

    get parentAccount() {
        const value = this.accountData ? getFieldValue(this.accountData, PARENT_NAME_FIELD) : null;
        const label = this.PARENT_ACCOUNT_LABEL_NO;
        return { value, label };
    }

    get parentUrl() {
        const parentId = this.getFieldData(PARENT_ID);
        return parentId?.value ? `/lightning/r/Account/${parentId.value}/view` : '#';
    }

    getFieldData(fieldApiName) {
        const value = this.accountData ? getFieldValue(this.accountData, fieldApiName) : null;
        const label = this.objectInfo?.fields?.[fieldApiName.fieldApiName]?.label || '';
        return { value, label };
    }
}
