import { LightningElement, api, track, wire } from 'lwc';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

import ORG_FIELD from '@salesforce/schema/Account.INT_OrganizationNumber__c';
import ORG_FORMULA_FIELD from '@salesforce/schema/Account.OrganizationNumberFormula__c';
import MAIN_INDUSTRY_FIELD from '@salesforce/schema/Account.CRM_MainIndustry__c';

import SECTOR_FIELD from '@salesforce/schema/Account.TAG_Sector__c';

import REGISTRATION_YEAR_FIELD from '@salesforce/schema/Account.CRM_RegistrationYear__c';

import PROFF_FIELD from '@salesforce/schema/Account.TAG_Proff_no__c';

import EMPLOYEES_FORMULA_FIELD from '@salesforce/schema/Account.CRM_NumberOfEmployeesFormula__c';

import PARENT_ID from '@salesforce/schema/Account.ParentId';
import PARENT_NAME_FIELD from '@salesforce/schema/Account.Parent.Name';
import { NavigationMixin } from 'lightning/navigation';
import LightningToast from 'lightning/toast';
//import FORM_FACTOR from '@salesforce/client/formFactor';
const ACCOUNT_FIELDS = [
    ORG_FIELD,
    ORG_FORMULA_FIELD,
    MAIN_INDUSTRY_FIELD,
    SECTOR_FIELD,
    REGISTRATION_YEAR_FIELD,
    PROFF_FIELD,
    EMPLOYEES_FORMULA_FIELD,
    PARENT_ID,
    PARENT_NAME_FIELD
];
export default class TagAccountHighlightsPanel extends NavigationMixin(LightningElement) {
    @api recordId;
    accountRecord;
    objectInfo;
    error;
    parentAccountUrl;
    PARENT_ACCOUNT_LABEL_NO = 'Overordnet konto';
    TOAST_SUCCESS = 'success';
    TOAST_ERROR = 'error';

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountRecord = data;
            console.log('Account record data: ' + JSON.stringify(data));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accountRecord = undefined;
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

    get organisationNumber() {
        return this.getFieldData(ORG_FIELD);
    }
    get organisationNumberFormula() {
        return this.getFieldData(ORG_FORMULA_FIELD);
    }
    get mainIndustry() {
        return this.getFieldData(MAIN_INDUSTRY_FIELD);
    }
    get sector() {
        return this.getFieldData(SECTOR_FIELD);
    }
    get registrationYear() {
        return this.getFieldData(REGISTRATION_YEAR_FIELD);
    }
    get proffNo() {
        return this.getFieldData(PROFF_FIELD);
    }
    get numberOfEmployeesFormula() {
        return this.getFieldData(EMPLOYEES_FORMULA_FIELD);
    }

    get parentAccount() {
        const id = this.accountRecord ? getFieldValue(this.accountRecord, PARENT_ID) : null;
        this.generateParentUrl(id);
        const label = this.PARENT_ACCOUNT_LABEL_NO;
        const value = this.accountRecord ? getFieldValue(this.accountRecord, PARENT_NAME_FIELD) : null;
        // Generate URL synchronously for standard record page
        const url = this.parentAccountUrl;
        return { id, label, value, url };
    }

    // Ny metode for å generere URL
    async generateParentUrl(recordId) {
        try {
            this.parentAccountUrl = await this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Error generating URL:', error);
            this.parentAccountUrl = `/${recordId}`; // Fallback
        }
    }
    // Helper method to get field value and label
    getFieldData(fieldApiName) {
        const value = this.accountRecord ? getFieldValue(this.accountRecord, fieldApiName) : null;
        const label = this.objectInfo?.fields?.[fieldApiName.fieldApiName]?.label || '';
        return { value, label };
    }

    handleCopy(event) {
        const hiddenInput = document.createElement('input');
        const eventValue = event.currentTarget.value;
        hiddenInput.value = eventValue;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
        console.log('Copying text:', eventValue);
        try {
            // eslint-disable-next-line @locker/locker/distorted-document-exec-command
            const successful = document.execCommand('copy');
            if (!successful) this.showCopyToast(this.TOAST_ERROR);
            else this.showCopyToast(this.TOAST_SUCCESS, eventValue);
        } catch (error) {
            this.showCopyToast(this.TOAST_ERROR);
        }
        document.body.removeChild(hiddenInput);
        event.currentTarget.focus();
    }

    showCopyToast(status, value) {
        var message = status === this.TOAST_SUCCESS ? value + ' kopiert til utklippstavlen.' : 'Kunne ikke kopiere';
        this.showLightningToast(status, message);
    }

    async showLightningToast(status, message) {
        await LightningToast.show(
            {
                label: message,
                variant: status
            },
            this
        );
    }

    @track actions = [
        { label: 'View Account Hierarchy', value: 'View Account Hierarchy', iconName: 'utility:hierarchy' }
    ];

    handleActionTriggered(event) {
        const actionValue = event.detail.value;
        console.log('Action triggered with value:', actionValue);
    }
}
