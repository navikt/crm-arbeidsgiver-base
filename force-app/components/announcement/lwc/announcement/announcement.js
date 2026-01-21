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

    HIDE_NOTE_TITLE = false;
    LIST_VIEW_API_NAME = 'Teams_Alle_innlegg';
    EXCLUDE_INACTIVE = true;
    MAX_TEXT_LENGTH = 1000;
    DEFAULT_LINK_LABEL = 'Si din mening (åpner Teams)';
    DEFAULT_PAGE_SIZE = 2;

    objectApiName = NOTE_OBJECT.objectApiName;
    listViewFields = this.convertSchemaFieldToPath([NAME, TEXT, LINK_URL, AUTHOR, PUBLISH_DATE, ACTIVE]);

    get pageSize() {
        return this.inputNumberOfRecordsToShow || this.DEFAULT_PAGE_SIZE;
    }
    get sortBy() {
        return ['-' + PUBLISH_DATE.objectApiName + '.' + PUBLISH_DATE.fieldApiName];
    }
    get whereClause() {
        if (this.EXCLUDE_INACTIVE) {
            return `{ TAG_Active__c: { eq: true } }`;
        }
        return null;
    }

    get title() {
        return this.inputTitle || 'Bli med å påvirke Salesforce Arbeidsgiver';
    }

    get helpText() {
        return this.inputHelpText || '';
    }

    get isNoteAdmin() {
        return hasArbeidsgiver_Manage_custom_notes;
    }

    get isEmptyState() {
        return !this.displayRecords || this.displayRecords.length === 0;
    }
    get isErrorState() {
        return this.userErrorMessage !== null;
    }

    lastViewedDate = new Date();
    @track userErrorMessage = null;
    @track displayRecords = [];
    @track listViewApiName = null; // Start med null, settes av getLastViewedDate

    @wire(getLastViewedDate, { listViewName: '$LIST_VIEW_API_NAME' })
    wiredListViewLastViewedDate({ error, data }) {
        if (data) {
            this.userErrorMessage = null;
            this.lastViewedDate = new Date(data);
            // Nå som lastViewedDate er hentet, aktiver getListRecordsByName
            this.listViewApiName = this.LIST_VIEW_API_NAME;
        } else if (error) {
            // console.error('Error fetching last viewed date:', error);
            if (error.status === 500) {
                this.userErrorMessage = 'Det oppstod en feil. Prøv igjen senere. Kontakt support om feilen vedvarer.';
            } else {
                this.userErrorMessage = 'Innlegg kan ikke vises akkurat nå. Feilen er registrert og vil bli undersøkt.';
            }
        }
    }

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$listViewFields',
        pageSize: '$pageSize',
        sortBy: '$sortBy',
        where: '$whereClause'
    })
    wireResult(result) {
        //console.log('result :', JSON.stringify(result, null, 2));
        if (result.data) {
            this.userErrorMessage = null;
            this.displayRecords = result.data.records.map((record) => this.createDataItemFromRecord(record));
        } else if (result.error) {
            this.userErrorMessage = 'Innlegg er ikke tilgjengelig for din bruker.';
            this.displayRecords = [];
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
                filterName: this.LIST_VIEW_API_NAME
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
        if (!publishDate) {
            return false;
        }
        const now = new Date();
        const timeDiff = now.getTime() - publishDate.getTime();
        const daysDiff = timeDiff / (1000 * 3600 * 24);
        return daysDiff <= 1; // Considered recent if within the last 1 day
    }
}
