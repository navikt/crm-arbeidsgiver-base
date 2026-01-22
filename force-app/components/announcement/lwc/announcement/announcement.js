import { LightningElement, api, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import getLastViewedDate from '@salesforce/apex/ListViewController.getListViewLastViewedDate';
import hasArbeidsgiver_Manage_custom_notes from '@salesforce/customPermission/Arbeidsgiver_Announcements_View_admin_options';
import NOTE_OBJECT from '@salesforce/schema/TAG_Announcement__c';

import { NavigationMixin } from 'lightning/navigation';

import NAME from '@salesforce/schema/TAG_Announcement__c.Name';
import TEXT from '@salesforce/schema/TAG_Announcement__c.TAG_Text_Content__c';
import LINK_URL from '@salesforce/schema/TAG_Announcement__c.TAG_Link_URL__c';
import AUTHOR from '@salesforce/schema/TAG_Announcement__c.TAG_Author_Name__c';

import ACTIVE from '@salesforce/schema/TAG_Announcement__c.TAG_Active__c';
import PUBLISH_DATE from '@salesforce/schema/TAG_Announcement__c.TAG_Publish_Date__c';

export default class Announcement extends NavigationMixin(LightningElement) {
    @api inputTitle;
    @api inputHelpText;
    @api inputNumberOfRecordsToShow;
    @api inputListViewApiName;
    @api inputRecentThresholdHours;

    HIDE_NOTE_TITLE = false;
    EXCLUDE_INACTIVE = true;
    DEFAULT_LINK_LABEL = 'Si din mening (åpner Teams)';

    objectApiName = NOTE_OBJECT.objectApiName;
    listViewFields = this.convertSchemaFieldToPath([NAME, TEXT, LINK_URL, AUTHOR, PUBLISH_DATE, ACTIVE]);
    sortBy = ['-' + PUBLISH_DATE.objectApiName + '.' + PUBLISH_DATE.fieldApiName];
    whereClause = this.EXCLUDE_INACTIVE ? `{ TAG_Active__c: { eq: true } }` : null;

    @track isLoading = true;
    lastViewedDate = new Date();
    @track userErrorMessage = null;
    @track displayRecords = [];
    @track listViewApiName = null;

    get isNoteAdmin() {
        return hasArbeidsgiver_Manage_custom_notes;
    }

    get showEmptyStateMessage() {
        return !this.isLoading && !this.userErrorMessage && (!this.displayRecords || this.displayRecords.length === 0);
    }
    get displayRecordsFound() {
        return !this.isLoading && !this.userErrorMessage && this.displayRecords && this.displayRecords.length > 0;
    }

    @wire(getLastViewedDate, { listViewName: '$inputListViewApiName', sObjectType: '$objectApiName' })
    wiredListViewLastViewedDate(result) {
        this.userErrorMessage = null;

        if (result.data) {
            try {
                this.lastViewedDate = result.data.lastViewedDate == null ? null : new Date(result.data.lastViewedDate);
            } catch (e) {
                console.error('Error parsing last viewed date:', e);
                this.lastViewedDate = null;
            }
            // Set listViewApiName to activate getListRecordsByName
            this.listViewApiName = this.inputListViewApiName;
        } else if (result.error) {
            this.userErrorMessage = 'Det oppstod en feil. Prøv igjen senere. Kontakt support om feilen vedvarer.';
            this.isLoading = false;
        }
    }

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$listViewFields',
        pageSize: '$inputNumberOfRecordsToShow',
        sortBy: '$sortBy',
        where: '$whereClause'
    })
    wireResult(result) {
        if (result.data) {
            this.displayRecords = result.data.records.map((record) => this.createDataItemFromRecord(record));
            this.userErrorMessage = null;
            this.isLoading = false;
        } else if (result.error) {
            this.userErrorMessage = 'Innlegg er ikke tilgjengelig for din bruker.';
            this.displayRecords = [];
            this.isLoading = false;
        }
    }

    // =========================
    // RECORD PROCESSING
    // =========================

    createDataItemFromRecord(record) {
        const title = this.HIDE_NOTE_TITLE ? '' : this.getFieldValue(record, NAME.fieldApiName);
        const url = this.getFieldValue(record, LINK_URL.fieldApiName);
        const urlLabel = url ? this.DEFAULT_LINK_LABEL : '';
        const text = this.getFieldValue(record, TEXT.fieldApiName);
        const publishDateField = this.getField(record, PUBLISH_DATE.fieldApiName);
        const publishedDate = publishDateField ? new Date(publishDateField.value) : null; // '2026-01-13T06:17:44.000Z'
        const publishDateDisplayValue = publishDateField ? publishDateField.displayValue : '';

        return {
            id: record.id,
            title: title,
            url: url,
            urlLabel: urlLabel,
            text: text,
            author: this.getFieldValue(record, AUTHOR.fieldApiName),
            canEdit: record.editable,
            published: publishedDate,
            publishedTooltip: publishDateDisplayValue,
            publishedClass: this.isRecentlyPublished(publishedDate) ? this.recordRecentStyle : '',
            articleClass: this.isPublishedSinceLastView(publishedDate) ? this.recordUnreadStyle : this.recordBaseStyle
        };
    }

    recordBaseStyle = 'slds-box slds-box_x-small announcement__item';
    recordRecentStyle = 'announcement__item--new';
    recordUnreadStyle = this.recordBaseStyle + ' announcement__item--unread';

    // =========================
    // EVENT HANDLERS
    // =========================

    handleEditClick(event) {
        const recordId = event.target.dataset.recordId;
        this.navigateToRecordEdit(recordId, this.objectApiName);
    }

    handleNewRecord() {
        this.navigateToRecordNew(this.objectApiName);
    }
    handleListViewClick(event) {
        event.preventDefault();
        this.navigateToListView(event);
    }

    // =========================
    // NAVIGATION METHODS
    // =========================

    navigateToRecordEdit(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'edit'
            }
        });
    }

    navigateToRecordNew(objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'
            },
            state: {
                useRecordTypeCheck: 'true'
            }
        });
    }

    navigateToListView(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: this.inputListViewApiName
            }
        });
    }

    // =========================
    // HELPERS
    // =========================

    getField(record, fieldName) {
        if (!fieldName) {
            return null;
        }
        const fieldData = record.fields[fieldName];
        if (!fieldData) {
            return null;
        }
        return fieldData;
    }

    getFieldValue(record, fieldName) {
        if (!fieldName) {
            return null;
        }
        const fieldData = record.fields[fieldName];
        if (!fieldData) {
            return null;
        }
        return fieldData.displayValue ?? fieldData.value ?? null;
    }

    convertSchemaFieldToPath(fieldsArray) {
        return fieldsArray.map((field) => {
            return field.objectApiName + '.' + field.fieldApiName;
        });
    }

    /* Check if announcements is new since last component view by user*/
    isPublishedSinceLastView(publishDate) {
        if (!this.lastViewedDate) {
            return false;
        }
        if (!publishDate) {
            return false;
        }
        const bufferTime = 1 * 60 * 1000; // 1 minute buffer
        const lastViewedWithBuffer = new Date(this.lastViewedDate.getTime() - bufferTime);
        return publishDate >= lastViewedWithBuffer;
    }

    /* Check if announcements is recently posted, within 1 day ago */
    isRecentlyPublished(publishDate) {
        if (!publishDate || !this.inputRecentThresholdHours || this.inputRecentThresholdHours < 0) {
            return false;
        }
        const now = new Date();
        const timeDiff = now.getTime() - publishDate.getTime();
        const hoursDiff = timeDiff / (1000 * 3600);
        return hoursDiff <= this.inputRecentThresholdHours; // Considered recent if within the last 24 hours
    }
}
