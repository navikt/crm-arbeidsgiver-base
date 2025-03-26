import { LightningElement, api, track, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/TAG_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class TagRelatedList extends NavigationMixin(LightningElement) {
    
    hoverTimer;
    hideTimer;
    
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
    @api inactiveRecordFilter; // Example: "Active__c = false"

    @track relatedRecords;
    @track isExpanded = false; // Accordion state

    @track popoverRecordData; // Holds the record data for the hovered row
    @track showPopover = false; // Flag to conditionally display popover
    @track popoverPosition = { top: 0, left: 0 };

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.getList();
    }

    get relatedObjectNames() {
        if (!this.displayedFields) return [];
        const fields = this.displayedFields.replace(/\s/g, '').split(',');
        const related = new Set();
        fields.forEach(field => {
            if (field.includes('.')) {
                let relationship = field.split('.')[0];
                related.add(relationship);
            }
        });
        return Array.from(related);
    }
    
    @wire(getObjectInfos, { objectApiNames: '$relatedObjectNames' })
    wiredRelatedObjectInfos({ data, error }) {
        if (data) {
            this.relatedObjectMetadata = data.results.reduce((acc, item) => {
                acc[item.result.apiName] = item.result.fields;
                return acc;
            }, {});
        } else if (error) {
            console.error('Error fetching related object metadata:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: '$relatedObjectApiName' })
    objectInfo;

    // Wire to refresh the list when the parent record changes
    @wire(getRecord, { recordId: '$recordId', fields: '$wireFields' })
    getaccountRecord({ data, error }) {
        if (data && this.dynamicUpdate === true) {
            this.getList();
        } else if (error) {
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

        const defaultValues = encodeDefaultFieldValues({
            [this.relationField]: this.recordId
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.relatedObjectApiName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
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
            // Parse the inactive filter if provided
            let filterField = null;
            let filterOperator = null;
            let filterValue = null;
            if (this.inactiveRecordFilter) {
                let regex = /^([^!<>=]+)\s*(=|!=)\s*(.*)$/;
                let match = this.inactiveRecordFilter.match(regex);
                if (match) {
                    filterField = match[1].trim();
                    filterOperator = match[2].trim();
                    filterValue = match[3].trim().toLowerCase();
                }
            }
            
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
                
                let isInactive = false;
                if (filterField) {
                    let fieldVal = this.resolve(filterField, dataRecord);
                    let recordValue = fieldVal !== null ? String(fieldVal).toLowerCase() : null;
    
                    if (filterOperator === "=") {
                        isInactive = (recordValue === filterValue);
                    } else if (filterOperator === "!=") {
                        isInactive = (recordValue !== filterValue && recordValue !== null);
                    }
                }
                
                let rowClass = 'slds-hint-parent';
                if (isInactive) {
                    rowClass += ' inactiveRow';
                }
                
                returnRecords.push({
                    recordFields: recordFields,
                    Id: dataRecord.Id,
                    isInactive: isInactive,
                    rowClass: rowClass
                });
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
             let style = 'vertical-align: middle; text-align: left; padding: 4px 8px; max-width: 33%';
             // Padding for the first cell.
             if (index === 0) {
                 style += 'padding-left: 1rem;';
             }
             if (index === arr.length - 1) {
                 style += 'padding-right: 0px;';
             }
             return { 
                 value: label, 
                 headerStyle: style
             };
        });
    }    

    get apexFieldList() {
        // Get fields from displayedFields and popoverFields
        let displayed = this.displayedFields ? this.displayedFields.replace(/\s/g, '').split(',') : [];
        let popover = this.popoverFields ? this.popoverFields.replace(/\s/g, '').split(',') : [];
        let combined = Array.from(new Set([...displayed, ...popover]));
        
        // extract the field name and add it to the list if not already present.
        if (this.inactiveRecordFilter) {
            let regex = /^([^!<>=]+)\s*(=|!=)\s*(.*)$/;
            let match = this.inactiveRecordFilter.match(regex);
            if (match) {
                let filterField = match[1].trim();
                if (!combined.includes(filterField)) {
                    combined.push(filterField);
                }
            }
        }
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

    handleMouseEnter(event) {
        const recordId = event.currentTarget.dataset.recordId;
        const rect = event.currentTarget.getBoundingClientRect();
        this.popoverPosition = {
            top: rect.top + 2,
            left: rect.left + 2
        };
        this.hoverTimer = window.setTimeout(() => {
            this.popoverRecordData = this.relatedRecords.find(rec => rec.Id === recordId);
            this.showPopover = true;
        }, 1000);
    }

    handleMouseLeave() {
        window.clearTimeout(this.hoverTimer);
        this.hideTimer = window.setTimeout(() => {
            this.showPopover = false;
        }, 200); // Delay closing popover to allow mouse movement
    }

    handlePopoverEnter() {
        // Prevent hiding when entering the popover
        window.clearTimeout(this.hideTimer);
    }

    // Getter to combine displayedFields with additional popoverFields
    get combinedPopoverFields() {
        return this.apexFieldList;
    }

    // Getter to prepare an array of objects with localized field labels and values from the hovered record
    get popoverFieldValues() {
        if (!this.popoverRecordData || !this.objectInfo.data) {
            return [];
        }
    
        return this.combinedPopoverFields.map(fieldApiName => {
            let fieldLabel;
            
            if (fieldApiName.includes('.')) {
                let [relationship, childField] = fieldApiName.split('.');
                
                if (this.relatedObjectMetadata[relationship] && this.relatedObjectMetadata[relationship][childField]) {
                    fieldLabel = this.relatedObjectMetadata[relationship][childField].label;
                } else {
                    fieldLabel = childField;
                }
            } else {
                fieldLabel = this.objectInfo.data.fields[fieldApiName]?.label || fieldApiName;
            }
    
            return {
                apiName: fieldLabel,
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
                    transform: translate(0, 0);`;
        }
        return '';
    }

    get popoverTitle() {
        if (this.popoverRecordData && this.displayedFieldList && this.displayedFieldList.length > 0 && this.objectInfo.data) {
            // Get the first field's API name from the displayedFields array
            let firstFieldApiName = this.displayedFieldList[0];
            let fieldValue = this.resolve(firstFieldApiName, this.popoverRecordData);
            return `${fieldValue}`;
        }
        return '';
    }
}
