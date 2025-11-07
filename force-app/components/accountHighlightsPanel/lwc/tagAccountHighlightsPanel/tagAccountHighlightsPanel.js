// Lightning Web Component core imports
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// UI Record API for data fetching
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

// Toast notifications
import LightningToast from 'lightning/toast';

// Account object and field references
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

// Account fields to retrieve
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

/**
 * TagAccountHighlightsPanel - Component for displaying key account information
 * Shows organization details, industry, sector, parent account, and other highlights
 * Supports copy-to-clipboard functionality for field values
 */
export default class TagAccountHighlightsPanel extends NavigationMixin(LightningElement) {
    // ========== Public Properties ==========
    /** Record ID of the Account being displayed */
    @api recordId;

    // ========== Private Properties ==========
    /** Cached Account record data */
    accountRecord;

    /** Account object metadata information */
    objectInfo;

    /** Error state from wire services */
    error;

    /** Generated URL for parent account navigation */
    parentAccountUrl;

    // ========== Constants ==========
    PARENT_ACCOUNT_LABEL_NO = 'Overordnet konto';
    TOAST_SUCCESS = 'success';
    TOAST_ERROR = 'error';
    popoverWidth = 380;
    // ========== Wire Methods ==========
    /**
     * Fetches Account record data using Lightning Data Service
     * @param {Object} result - Wire service result containing error or data
     */
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountRecord = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accountRecord = undefined;
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
     * Returns organization number field data
     * @returns {Object} Object containing value and label
     */
    get organisationNumber() {
        return this.getFieldData(ORG_FIELD);
    }

    /** Organization number formula field data */
    get organisationNumberFormula() {
        return this.getFieldData(ORG_FORMULA_FIELD);
    }

    /** Main industry field data */
    get mainIndustry() {
        return this.getFieldData(MAIN_INDUSTRY_FIELD);
    }

    /** Sector field data */
    get sector() {
        return this.getFieldData(SECTOR_FIELD);
    }

    /** Registration year field data */
    get registrationYear() {
        return this.getFieldData(REGISTRATION_YEAR_FIELD);
    }

    /** Proff number field data */
    get proffNo() {
        return this.getFieldData(PROFF_FIELD);
    }

    /** Number of employees formula field data */
    get numberOfEmployeesFormula() {
        return this.getFieldData(EMPLOYEES_FORMULA_FIELD);
    }

    /**
     * Returns parent account information with navigation URL
     * @returns {Object} Object containing id, label, value, and url
     */
    get parentAccount() {
        const id = this.accountRecord ? getFieldValue(this.accountRecord, PARENT_ID) : null;
        this.generateParentUrl(id);
        const label = this.PARENT_ACCOUNT_LABEL_NO;
        const value = this.accountRecord ? getFieldValue(this.accountRecord, PARENT_NAME_FIELD) : null;
        const url = this.parentAccountUrl;
        return { id, label, value, url };
    }

    // ========== Helper Methods ==========
    /**
     * Generates a navigation URL for the parent account
     * @param {String} recordId - Parent account record ID
     */
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

    /**
     * Helper method to get field value and label from Account record
     * @param {Object} fieldApiName - Salesforce field reference
     * @returns {Object} Object containing value and label properties
     */
    getFieldData(fieldApiName) {
        const value = this.accountRecord ? getFieldValue(this.accountRecord, fieldApiName) : null;
        const label = this.objectInfo?.fields?.[fieldApiName.fieldApiName]?.label || '';
        return { value, label };
    }

    // ========== Event Handlers ==========
    /**
     * Handles copy-to-clipboard functionality for field values
     * Uses deprecated execCommand for Locker Service compatibility
     * @param {Event} event - Click event from copy button
     */
    handleCopy(event) {
        const hiddenInput = document.createElement('input');
        const eventValue = event.currentTarget.value;
        hiddenInput.value = eventValue;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
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

    /**
     * Displays a toast notification for copy operation result
     * @param {String} status - Toast variant (success or error)
     * @param {String} value - Copied value to display in success message
     */
    showCopyToast(status, value) {
        var message = status === this.TOAST_SUCCESS ? value + ' kopiert til utklippstavlen.' : 'Kunne ikke kopiere';
        this.showLightningToast(status, message);
    }

    /**
     * Shows a Lightning toast notification
     * @param {String} status - Toast variant (success, error, etc.)
     * @param {String} message - Message to display
     */
    async showLightningToast(status, message) {
        await LightningToast.show(
            {
                label: message,
                variant: status
            },
            this
        );
    }
}
