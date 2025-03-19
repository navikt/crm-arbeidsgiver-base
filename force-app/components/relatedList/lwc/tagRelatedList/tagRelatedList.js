import { LightningElement, api, track, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/TAG_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class TagRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api listTitle; // Title of the list.
    @api iconName; // Displayed icon.
    @api columnLabels; // Columns to be displayed.
    @api displayedFields = null;
    @api relatedObjectApiName; // Related object name.
    @api relationField; // Lookup/master-detail field name.
    @api parentRelationField; // Parent relationship field in the junction.
    @api filterConditions; // Optional filter conditions.
    @api headerColor; // Header background color.
    @api dynamicUpdate = false; // Auto-refresh flag.
    @api maxHeight = 20; // Max height in em.
    @api clickableRows; // Enable row click navigation.
    @api wireFields;
    @api collapsedCount = 0; // Number of records to show when collapsed
    @api popoverFields; //Popover additional fields (comma separated)
    @api showNewRecordButton;
    @api newRecordButtonLabel; // Button label for New Record button


    @track relatedRecords;
    @track isExpanded = false; // Accordion state

    @track popoverRecordData; // Holds the record data for the hovered row
    @track showPopover = false; // Flag to conditionally display popover
    hoverTimer; // Timer for delayed popover display
    @track popoverPosition = { top: 0, left: 0 };

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.getList();
    }

    @wire(getObjectInfo, { objectApiName: '$relatedObjectApiName' })
    objectInfo;

    // Wire to refresh the list when the parent record changes
    @wire(getRecord, { recordId: '$recordId', fields: '$wireFields' })
    getaccountRecord({ data, error }) {
        if (data && this.dynamicUpdate === true) {
            this.getList();
        } else if (error) {
            // Handle error accordingly
        }
    }

    // Retrieve related records from Apex
    getList() {
        getRelatedList({
            fieldNames: this.apexFieldList,
            parentId: this.recordId,
            objectApiName: this.relatedObjectApiName,
            relationField: this.relationField,
            parentRelationField: this.parentRelationField,
            parentObjectApiName: this.objectApiName,
            filterConditions: this.filterConditions
        })
            .then((data) => {
                this.relatedRecords = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }

    // Toggle the accordion state
    toggleAccordion() {
        this.isExpanded = !this.isExpanded;
    }

    get chevronIcon() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    // Handle row click event if clickableRows is enabled
    handleRowClick(event) {
        let recordIndex = event.currentTarget.dataset.value;
        this.navigateToRecord(this.relatedRecords[recordIndex].Id);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.relatedObjectApiName,
                actionName: 'view'
            }
        });
    }

    handleNewRecord(event) {
        // Prevent the header's onclick from firing
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.relatedObjectApiName,
                actionName: 'new'
            }
        });
    }

    // Compute records to display based on whether the list is expanded or collapsed
    get displayedRecords() {
        const records = this.listRecords;
        if (!this.isExpanded && records.length > this.collapsedCount) {
            return records.slice(0, this.collapsedCount);
        }
        return records;
    }

    get displayedFieldList() {
        return this.displayedFields ? this.displayedFields.replace(/\s/g, '').split(',') : [];
    }

    // Transform the raw related records into a display-friendly format
    get listRecords() {
        let returnRecords = [];
        if (this.relatedRecords) {
            this.relatedRecords.forEach((dataRecord) => {
                let recordFields = [];
                this.displayedFieldList.forEach((key) => {
                    if (key !== 'Id') {
                        recordFields.push({
                            label: key,
                            value: this.resolve(key, dataRecord)
                        });
                    }
                });
                returnRecords.push({ recordFields: recordFields, Id: dataRecord.Id });
            });
        }
        return returnRecords;
    }

    // Build the card title with record count
    get cardTitle() {
        const numRecords = this.relatedRecords ? this.relatedRecords.length : 0;
        return `${this.listTitle} (${numRecords})`;
    }

    get headerBackground() {
        return this.headerColor 
            ? `background-color: ${this.headerColor}; border: 1px solid ${this.headerColor}; cursor: pointer;`
            : 'cursor: pointer;';
    }

    get tableHeaderStyle() {
        return `width: 100%; max-height: ${this.maxHeight}em`;
    }

    get scrollableStyle() {
        return `max-height: ${this.maxHeight}em`;
    }

    // Prepare column labels array for rendering the header row
    get fieldLabels() {
        let labels = this.columnLabels 
            ? this.columnLabels.replace(/\s/g, '').split(',') 
            : [];
        return labels.map((label, index, arr) => {
             // Base style for every header cell.
             let style = 'vertical-align: middle; text-align: left; padding: 4px 8px;';
             // Remove extra left padding for the first cell.
             if (index === 0) {
                 style += 'padding-left: 5px;';
             }
             // Remove extra right padding for the last cell.
             if (index === arr.length - 1) {
                 style += 'padding-right: 0px;';
             }
             return { 
                 value: label, 
                 headerStyle: style
             };
        });
    }    

    // Parse and combine the displayed fields and popoverFields strings into an array
    get apexFieldList() {
        // Get displayedFields (if any)
        let displayed = this.displayedFields ? this.displayedFields.replace(/\s/g, '').split(',') : [];
        // Get popoverFields (if any)
        let popover = this.popoverFields ? this.popoverFields.replace(/\s/g, '').split(',') : [];
        // Combine them and remove duplicates
        let combined = Array.from(new Set([...displayed, ...popover]));
        return combined;
    }

    get icon() {
        return this.iconName && this.iconName !== '' ? this.iconName : null;
    }

    get toggleIcon() {
        return this.isExpanded ? '▼' : '▶';
    }

    get showRecords() {
        return this.relatedRecords && this.relatedRecords.length > 0 && this.isExpanded;
    }    
    
    resolve(path, obj) {
        if (typeof path !== 'string') {
            throw new Error('Path must be a string');
        }
    
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || {});
    }

    // Event handler for mouse enter on a record row
    handleMouseEnter(event) {
        const recordId = event.currentTarget.dataset.recordId;
        const rect = event.currentTarget.getBoundingClientRect();
        // Adjusting the position slightly (you can fine‑tune the offsets)
        this.popoverPosition = {
            top: rect.top + 10,
            left: rect.left + 10
        };
        this.hoverTimer = window.setTimeout(() => {
            this.popoverRecordData = this.relatedRecords.find(rec => rec.Id === recordId);
            this.showPopover = true;
        }, 1500);
    }

    // Event handler for mouse leave from a record row (or popover)
    handleMouseLeave() {
        window.clearTimeout(this.hoverTimer);
        this.showPopover = false;
    }

    // Getter to combine displayedFields with additional popoverFields
    get combinedPopoverFields() {
        return this.apexFieldList;
    }

    // Getter to prepare an array of objects with localized field labels and values from the hovered record
    get popoverFieldValues() {
        // Ensure we have the record data and the object metadata
        if (!this.popoverRecordData || !this.objectInfo.data) {
            return [];
        }
        return this.combinedPopoverFields.map(fieldApiName => {
            // Look up the localized label (if available); if not, fallback to field API name
            let fieldLabel = this.objectInfo.data.fields[fieldApiName] ? 
                                this.objectInfo.data.fields[fieldApiName].label : 
                                fieldApiName;
            return {
                apiName: fieldLabel, // Using the localized label here instead of the API name
                value: this.resolve(fieldApiName, this.popoverRecordData)
            };
        });
    }    

    // Getter for popover style
    get popoverStyle() {
        if (this.popoverPosition) {
            // Get the host element's bounding rectangle
            const containerRect = this.template.host.getBoundingClientRect();
            // Compute coordinates relative to the host container
            const relativeLeft = this.popoverPosition.left - containerRect.left;
            const relativeTop = this.popoverPosition.top - containerRect.top;
            // Add a vertical offset (+20px) and change the transform to not shift upward
            return `position: absolute; 
                    top: ${relativeTop + 20}px; 
                    left: ${relativeLeft}px; 
                    z-index: 1000; 
                    transform: translate(-50%, 0);`;
        }
        return '';
    }
}
