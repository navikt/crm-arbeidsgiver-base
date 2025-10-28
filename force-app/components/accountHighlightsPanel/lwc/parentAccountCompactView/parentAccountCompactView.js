import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

// Import fields from parent account
const PARENT_ACCOUNT_FIELDS = [
    'Account.Name',
    'Account.INT_OrganizationNumber__c',
    'Account.OrganizationNumberFormula__c',
    'Account.CRM_MainIndustry__c',
    'Account.CRM_NumberOfEmployeesFormula__c',
    'Account.CRM_RegistrationYear__c',
    'Account.ParentId',
    'Account.Parent.Name'
];

/**
 * Component for displaying parent account information in a compact layout format
 * Similar to the standard Salesforce Account Compact Layout
 */
export default class ParentAccountCompactView extends NavigationMixin(LightningElement) {
    @api parentAccountId;
    objectInfo;
    parentAccountData;
    error;
    isLoading = false;

    @wire(getRecord, { recordId: '$parentAccountId', fields: PARENT_ACCOUNT_FIELDS })
    wiredParentAccount({ error, data }) {
        if (data) {
            this.parentAccountData = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = 'Kunne ikke laste overordnet konto';
            this.parentAccountData = undefined;
            this.isLoading = false;
            console.error('Error loading parent account:', error);
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
        return this.getFieldData('Account.Name');
    }
    get organisationNumber() {
        return this.getFieldData('Account.OrganizationNumberFormula__c');
    }

    get mainIndustry() {
        return this.getFieldData('Account.CRM_MainIndustry__c');
    }

    get numberOfEmployees() {
        return this.getFieldData('Account.CRM_NumberOfEmployeesFormula__c');
    }

    get registrationYear() {
        return this.getFieldData('Account.CRM_RegistrationYear__c');
    }

    get accountUrl() {
        return this.parentAccountId ? `/lightning/r/Account/${this.parentAccountId}/view` : '#';
    }
    get parentAccount() {
        return this.getFieldData('Account.Parent.Name');
    }

    get parentUrl() {
        const parentId = this.parentAccountData?.fields?.ParentId?.value;
        return parentId ? `/lightning/r/Account/${parentId}/view` : '#';
    }

    getFieldData(fieldApiName) {
        const value = this.parentAccountData ? getFieldValue(this.parentAccountData, fieldApiName) : null;
        const label = this.objectInfo?.fields?.[fieldApiName.fieldApiName]?.label || '';
        return { value, label };
    }

    /**
     * Navigate to Account Hierarchy view
     */
    navigateToHierarchy() {
        if (!this.parentAccountId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.parentAccountId,
                objectApiName: 'Account',
                relationshipApiName: 'Hierarchy',
                actionName: 'view'
            }
        });
    }
}
