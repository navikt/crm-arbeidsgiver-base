import { LightningElement, api, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import hasArbeidsgiver_Manage_custom_notes from '@salesforce/customPermission/Arbeidsgiver_Manage_custom_notes';
import NOTE_OBJECT from '@salesforce/schema/TAG_Note__c';

import { NavigationMixin } from 'lightning/navigation';

import NAME from '@salesforce/schema/TAG_Note__c.Name';
import TEXT from '@salesforce/schema/TAG_Note__c.TAG_Text_Content__c';
import LINK_URL from '@salesforce/schema/TAG_Note__c.TAG_Link_URL__c';
import AUTHOR from '@salesforce/schema/TAG_Note__c.TAG_Author_Name__c';

import ACTIVE from '@salesforce/schema/TAG_Note__c.TAG_Active__c';
import PUBLISH_DATE from '@salesforce/schema/TAG_Note__c.TAG_Publish_Date__c';
import UNPUBLISH_DATE from '@salesforce/schema/TAG_Note__c.TAG_Unpublish_Date__c';

export default class Announcement extends NavigationMixin(LightningElement) {
    objectApiName = NOTE_OBJECT.objectApiName;
    @api inputLabel;
    @api inputHelpText;
    fields = this.convertSchemaFieldToPath([NAME, TEXT, LINK_URL, AUTHOR, PUBLISH_DATE, UNPUBLISH_DATE, ACTIVE]);

    excludeInactive = false;
    maxTextLength = 200;

    pageSize = 4;
    sortBy = '-' + PUBLISH_DATE.objectApiName + '.' + PUBLISH_DATE.fieldApiName;
    @track records = [];

    @api listViewApiName = 'PublishedNotes';
    listViewRecords;

    get label() {
        return this.inputLabel || 'Diskusjoner på Teams - Bli med!';
    }

    get helpText() {
        return this.inputHelpText || '';
    }

    get mode() {
        return 'view';
    }
    get density() {
        return 'Comfy';
    }
    get columns() {
        return '1';
    }
    get filter() {
        if (this.excludeInactive) {
            return `{ TAG_Active__c: { eq: true } }`;
        }
        return null;
    }
    get isNoteAdmin() {
        return hasArbeidsgiver_Manage_custom_notes;
    }

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$fields',
        pageSize: '$pageSize',
        sortBy: '$sortField',
        where: '$filter'
    })
    wiredListViewRecords(result) {
        console.log('result :', JSON.stringify(result, null, 2));
        if (result.data) {
            this.listViewRecords = result;
            this.records = result.data.records.map((record) => this.createDataItemFromRecord(record));
            //console.log('listRecords data:', JSON.stringify(this.records, null, 2));
        } else if (result.error) {
            console.error('Feil ved henting av records:', result.error);
            this.records = [];
        }
    }

    // =========================
    // RECORD PROCESSING
    // =========================

    createDataItemFromRecord(record) {
        return {
            id: record.id,
            title: this.getFieldValue(record, NAME.fieldApiName),
            url: this.getFieldValue(record, LINK_URL.fieldApiName),
            urlLabel: this.getFieldValue(record, LINK_URL.fieldApiName) ? '[Les på Teams]' : '',
            text: this.abbriviateText(this.getFieldValue(record, TEXT.fieldApiName), this.maxTextLength),
            published: this.getFieldValue(record, PUBLISH_DATE.fieldApiName),
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

    handleLinkClicked(event) {
        event.preventDefault();
        this.navigateToExternalUrl(event.target.dataset.url);
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
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: this.listViewApiName
            }
        });
    }

    navigateToExternalUrl(url) {}

    // =========================
    // HELPERS
    // =========================

    getFieldValue(record, fieldName) {
        //console.log('Getting field value for:', fieldName);
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
