import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getSettings from '@salesforce/apex/BadgeController.getSettings';
import { getRecord } from 'lightning/uiRecordApi';
import getRecords from '@salesforce/apex/BadgeController.getRecords';

export default class BadgePage extends LightningElement {
    @track recordId;
    @track badgeKey;
    @track isConfigLoaded = false;

    @track iconName;
    @track cardTitle;

    // Small, Medium, Large
    get isMobile() {
        if (this.formFactor) {
            return this.formFactor;
        }
        return window.innerWidth <= 768; // Initialize directly
    }

    @track records = [];
    @track error;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef) {
            this.badgeKey = pageRef?.state?.c__badge;
            this.recordId = pageRef?.state?.c__id;
            this.initBadgeFlow();
        }
    }

    initBadgeFlow() {
        if (this.recordId && this.badgeKey) {
            getSettings({ badgeKey: this.badgeKey })
                .then((data) => {
                    if (data) {
                        this.cardTitle = data.listTitle;
                        this.iconName = data.icon;
                        this.isConfigLoaded = true;
                        this.getList();
                    } else {
                        console.error('No settings found for badge type:', this.badgeKey);
                    }
                })
                .catch((error) => {
                    this.handleError('Error retrieving badge settings', error);
                });
        }
    }

    // Fetch related records
    getList() {
        console.log('Get records');
        getRecords({
            recordId: this.recordId,
            badgeKey: this.badgeKey
        })
            .then((data) => {
                this.records = data && data.length > 0 ? data : [];
                console.log('Records returned:', JSON.stringify(this.records));
            })
            .catch((error) => {
                this.handleError('Error retrieving related records', error);
            });
    }

    get recordsCount() {
        return this.records.length;
    }
    get isEmpty() {
        return this.records.length === 0;
    }
    /*
    for each record, remove records[i].field[0] and add it as records[i].recordUrl instead
    */
    get recordListTiles() {
        if (this.records && this.records.length > 0) {
            try {
                // Create a new list by mapping over the original records
                const newRecordsList = this.records.map((record) => {
                    console.log('RECORD:', JSON.stringify(record));

                    // Ensure fields array exists and has at least one element
                    if (record.fields && record.fields.length > 0) {
                        const fieldsCopy = [...record.fields];
                        const field = fieldsCopy.shift(); // Remove the first field
                        console.log('Removed field:', field);

                        return {
                            ...record,
                            title: field.value,
                            recordUrl: `/lightning/r/${record.id}/view`,
                            fields: fieldsCopy // Keep the remaining fields intact
                        };
                    }

                    // Return the record as-is if fields are empty or undefined
                    return { ...record, fields: [] };
                });

                console.log('New record list:', JSON.stringify(newRecordsList));
                return newRecordsList;
            } catch (error) {
                this.handleError('Error creating recordListTiles', error);
                return [];
            }
        }
        return [];
    }

    // Create columns configuration for the datatable based on first record[0].fields
    // for each field in record[0].fields, get label, fieldname and type and create column object
    get columnsConfig() {
        if (this.records && this.records.length > 0) {
            const columns = this.records[0].fields.map((field) => {
                return {
                    label: field.label,
                    fieldName: field.fieldName,
                    type: field.type,
                    typeAttributes: field.typeAttributes,
                    sortable: false,
                    cellAttributes: {
                        alignment: 'left'
                    }
                };
            });

            // Modifiser første kolonne til å vises som link
            columns[0].type = 'customName';
            columns[0].typeAttributes = {
                recordUrl: { fieldName: 'recordUrl' }
            };

            // console.log('Columns:', JSON.stringify(columns));
            return columns;
        }
        return [];
    }

    // Return list of records for data table
    get recordsList() {
        if (this.records && this.records.length > 0) {
            return this.records.map((record) => {
                const recordData = {};

                record.fields.forEach((field) => {
                    recordData[field.fieldName] = field.value;
                });
                recordData.recordUrl = `/lightning/r/${record.id}/view`;
                //  console.log('recordData:', JSON.stringify(recordData));
                return recordData;
            });
        }
        return [];
    }

    /** Get Account name from breadcrumbs */

    @wire(getRecord, { recordId: '$recordId', fields: '$dynamicField' })
    wiredRecordFields({ error, data }) {
        if (data) {
            this.parentRecordName = data.fields[this.fieldApiName].value;
        } else if (error) {
            // Handle error
            console.error(error);
        }
    }
    get dynamicField() {
        return [`${this.parentRecordObject}.${this.fieldApiName}`];
    }
    parentRecordObject = 'Account';
    fieldApiName = 'Name';
    parentRecordName;

    get parentRecordUrl() {
        return `/${this.recordId}`;
    }

    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
}
