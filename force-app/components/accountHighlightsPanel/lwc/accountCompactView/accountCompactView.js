// Lightning Web Component core imports
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// UI Record API for data fetching
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

// Account object and field references
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ORG_FORMULA_FIELD from '@salesforce/schema/Account.OrganizationNumberFormula__c';
import MAIN_INDUSTRY_FIELD from '@salesforce/schema/Account.CRM_MainIndustry__c';
import REGISTRATION_YEAR_FIELD from '@salesforce/schema/Account.CRM_RegistrationYear__c';
import EMPLOYEES_FORMULA_FIELD from '@salesforce/schema/Account.CRM_NumberOfEmployeesFormula__c';
import PARENT_ID from '@salesforce/schema/Account.ParentId';
import PARENT_NAME_FIELD from '@salesforce/schema/Account.Parent.Name';

// Account fields to retrieve
const ACCOUNT_FIELDS = [
    ACCOUNT_NAME,
    ORG_FORMULA_FIELD,
    MAIN_INDUSTRY_FIELD,
    REGISTRATION_YEAR_FIELD,
    EMPLOYEES_FORMULA_FIELD,
    PARENT_ID,
    PARENT_NAME_FIELD
];

/**
 * AccountCompactView - Component for displaying account information in a compact layout format
 * Similar to the standard Salesforce Account Compact Layout
 * Displays key account fields like organization number, industry, employees, and parent account
 */
export default class AccountCompactView extends NavigationMixin(LightningElement) {
    // ========== Public Properties ==========
    /** Record ID of the Account being displayed */
    @api recordId;

    // ========== Private Properties ==========
    /** Account object metadata information */
    objectInfo;

    /** Cached Account record data */
    accountData;

    /** Error state from wire services */
    error;

    /** Loading state indicator */
    isLoading = false;

    // ========== Constants ==========
    /** Label for parent account field (hardcoded since standard label is unavailable in this context) */
    PARENT_ACCOUNT_LABEL_NO = 'Overordnet konto';

    // ========== Wire Methods ==========
    /**
     * Fetches Account record data using Lightning Data Service
     * @param {Object} result - Wire service result containing error or data
     */
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

    /**
     * Fetches Account object metadata for field labels
     * @param {Object} result - Wire service result containing error or data
     */
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

    // ========== Getter Methods for Account Fields ==========
    /**
     * Returns account name field data
     * @returns {Object} Object containing value and label
     */
    get name() {
        return this.getFieldData(ACCOUNT_NAME);
    }

    /**
     * Returns organization number field data
     * @returns {Object} Object containing value and label
     */
    get organisationNumber() {
        return this.getFieldData(ORG_FORMULA_FIELD);
    }

    /**
     * Returns main industry field data
     * @returns {Object} Object containing value and label
     */
    get mainIndustry() {
        return this.getFieldData(MAIN_INDUSTRY_FIELD);
    }

    /**
     * Returns number of employees field data
     * @returns {Object} Object containing value and label
     */
    get numberOfEmployees() {
        return this.getFieldData(EMPLOYEES_FORMULA_FIELD);
    }

    /**
     * Returns registration year field data
     * @returns {Object} Object containing value and label
     */
    get registrationYear() {
        return this.getFieldData(REGISTRATION_YEAR_FIELD);
    }

    /**
     * Returns the Lightning navigation URL for the current account
     * @returns {String} Account detail page URL
     */
    get accountUrl() {
        return this.recordId ? `/lightning/r/Account/${this.recordId}/view` : '#';
    }

    /**
     * Returns parent account information
     * @returns {Object} Object containing value and label for parent account
     */
    get parentAccount() {
        const value = this.accountData ? getFieldValue(this.accountData, PARENT_NAME_FIELD) : null;
        const label = this.PARENT_ACCOUNT_LABEL_NO;
        return { value, label };
    }

    /**
     * Returns the Lightning navigation URL for the parent account
     * @returns {String} Parent account detail page URL
     */
    get parentUrl() {
        const parentId = this.getFieldData(PARENT_ID);
        return parentId?.value ? `/lightning/r/Account/${parentId.value}/view` : '#';
    }

    // ========== Helper Methods ==========
    /**
     * Helper method to get field value and label from Account record
     * @param {Object} fieldApiName - Salesforce field reference
     * @returns {Object} Object containing value and label properties
     */
    getFieldData(fieldApiName) {
        const value = this.accountData ? getFieldValue(this.accountData, fieldApiName) : null;
        const label = this.objectInfo?.fields?.[fieldApiName.fieldApiName]?.label || '';
        return { value, label };
    }
}
