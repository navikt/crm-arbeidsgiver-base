import { LightningElement, api, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import hasArbeidsgiver_Manage_custom_notes from '@salesforce/customPermission/Arbeidsgiver_Announcements_View_admin_options';
import NOTE_OBJECT from '@salesforce/schema/TAG_Announcement__c';

import { NavigationMixin } from 'lightning/navigation';

import NAME from '@salesforce/schema/TAG_Announcement__c.Name';
import TEXT from '@salesforce/schema/TAG_Announcement__c.TAG_Text_Content__c';
import LINK_URL from '@salesforce/schema/TAG_Announcement__c.TAG_Link_URL__c';
import AUTHOR from '@salesforce/schema/TAG_Announcement__c.TAG_Author_Name__c';

import ACTIVE from '@salesforce/schema/TAG_Announcement__c.TAG_Active__c';
import PUBLISH_DATE from '@salesforce/schema/TAG_Announcement__c.TAG_Publish_Date__c';
import UNPUBLISH_DATE from '@salesforce/schema/TAG_Announcement__c.TAG_Unpublish_Date__c';

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
    listViewFields = this.convertSchemaFieldToPath([
        NAME,
        TEXT,
        LINK_URL,
        AUTHOR,
        PUBLISH_DATE,
        UNPUBLISH_DATE,
        ACTIVE
    ]);

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
    get displayRecordsFound() {
        return this.displayRecords && this.displayRecords.length > 0;
    }

    @track displayRecords = [];

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$LIST_VIEW_API_NAME',
        fields: '$listViewFields',
        pageSize: '$pageSize',
        sortBy: '$sortBy',
        where: '$whereClause'
    })
    wireResult(result) {
        // console.log('result :', JSON.stringify(result, null, 2));
        if (result.data) {
            this.displayRecords = result.data.records.map((record) => this.createDataItemFromRecord(record));
        } else if (result.error) {
            console.error('Feil ved henting av records:', result.error);
            this.displayRecords = [];
        }
    }

    // =========================
    // RECORD PROCESSING
    // =========================

    createDataItemFromRecord(record) {
        var title = this.HIDE_NOTE_TITLE ? '' : this.getFieldValue(record, NAME.fieldApiName);
        var url = this.getFieldValue(record, LINK_URL.fieldApiName);
        var urlLabel = url ? this.DEFAULT_LINK_LABEL : '';
        var text = this.abbriviateText(this.getFieldValue(record, TEXT.fieldApiName), this.MAX_TEXT_LENGTH);
        var publishDateField = this.getField(record, PUBLISH_DATE.fieldApiName);
        var publishDateTime = publishDateField ? new Date(publishDateField.value) : null;
        var publishDateDisplayValue = publishDateField ? publishDateField.displayValue : '';

        return {
            id: record.id,
            title: title,
            url: url,
            urlLabel: urlLabel,
            text: text,
            published: publishDateTime,
            publishedTooltip: publishDateDisplayValue,
            author: this.getFieldValue(record, AUTHOR.fieldApiName),
            canEdit: record.editable
        };
    }

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
            return '';
        }
        const fieldData = record.fields[fieldName];
        if (!fieldData) {
            return '';
        }
        return fieldData;
    }

    getFieldValue(record, fieldName) {
        if (!fieldName) {
            return '';
        }
        const fieldData = record.fields[fieldName];
        if (!fieldData) {
            return '';
        }
        return fieldData.displayValue ?? fieldData.value ?? '';
    }

    convertSchemaFieldToPath(fieldsArray) {
        return fieldsArray.map((field) => {
            return field.objectApiName + '.' + field.fieldApiName;
        });
    }

    abbriviateText(text, maxLength) {
        if (!maxLength || maxLength <= 0) {
            return text;
        }
        if (text.length <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength) + '...';
    }
}
