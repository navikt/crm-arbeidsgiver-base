import { LightningElement, api, track, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/TAG_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import TEAM_MEMBER_ROLE_FIELD from '@salesforce/schema/AccountTeamMember.TeamMemberRole';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class TagRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api listTitle; // Title of the list.
    @api iconName; // Displayed icon.
    @api columnLabels; // Columns to be displayed.
    @api displayedFields = null;
    @api relatedObjectApiName; // Related object name.
    @api relationField; // Lookup/master-detail field name.
    @api parentRelationField; // Deprecated: kept for backwards compatibility with deployed FlexiPages. No longer used.
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
    @api iconNamePopover;
    @api inactivePrefix;

    @track relatedRecords;
    @track isExpanded = false; // Accordion state
    @track teamMemberRoleMapping;

    flowApiName = 'TAG_Create_New_Contact_Screen';

    get useFlowForNewRecord() {
        return this.relatedObjectApiName === 'Contact' || this.relatedObjectApiName === 'AccountContactRelation';
    }

    get flowInputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.getList();
    }

    get relatedObjectNames() {
        if (!this.displayedFields) return [];
        const fields = this.displayedFields.replace(/\s/g, '').split(',');
        const related = new Set();
        fields.forEach((field) => {
            if (field.includes('.')) {
                let relationship = field.split('.')[0];
                related.add(relationship);
            }
        });
        return Array.from(related);
    }

    get listDescription() {
        const count = this.relatedRecords ? this.relatedRecords.length : 0;
        const title = this.listTitle ?? 'relaterte poster';
        return `Tabell med ${count} rader: ${title}`;
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

    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: TEAM_MEMBER_ROLE_FIELD
    })
    wiredTeamMemberRolePicklist({ data, error }) {
        if (data) {
            this.teamMemberRoleMapping = data.values.reduce((acc, entry) => {
                acc[entry.value] = entry.label;
                return acc;
            }, {});
        } else if (error) {
            console.error('Error fetching picklist values for TeamMemberRole:', error);
        }
    }

    // Retrieve related records from Apex
    getList() {
        getRelatedList({
            fieldNames: this.apexFieldList,
            parentId: this.recordId,
            objectApiName: this.relatedObjectApiName,
            relationField: this.relationField,
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

    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
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

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.getList();
        }
    }

    // Compute records to display based on whether the list is expanded or collapsed
    get displayedRecords() {
        const records = this.listRecords;
        return !this.isExpanded && records.length > this.collapsedCount
            ? records.slice(0, this.collapsedCount)
            : records;
    }

    buildRecordLink(record) {
        // AccountContactRelation skal navigere til Contact, ikke AccountContactRelation
        if (this.relatedObjectApiName === 'AccountContactRelation' && record.ContactId) {
            return `/lightning/r/Contact/${record.ContactId}/view`;
        }
        return `/lightning/r/${this.relatedObjectApiName}/${record.Id}/view`;
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
                let isInactive = false;
                if (filterField) {
                    let fieldVal = this.resolve(filterField, dataRecord);
                    let recordValue = fieldVal !== null ? String(fieldVal).toLowerCase() : null;

                    if (filterOperator === '=') {
                        isInactive = recordValue === filterValue;
                    } else if (filterOperator === '!=') {
                        isInactive = recordValue !== filterValue && recordValue !== null;
                    }
                }

                let recordFields = [];
                const columnLabelList = this.columnLabels ? this.columnLabels.split(',').map((l) => l.trim()) : [];
                this.displayedFieldList.forEach((key, index) => {
                    if (key !== 'Id') {
                        let rawValue = this.resolve(key, dataRecord);
                        if (
                            key === 'TeamMemberRole' &&
                            this.teamMemberRoleMapping &&
                            this.teamMemberRoleMapping[rawValue]
                        ) {
                            rawValue = this.teamMemberRoleMapping[rawValue];
                        }
                        if (index === 0 && isInactive && this.inactivePrefix) {
                            rawValue = this.inactivePrefix + ' ' + rawValue;
                        }
                        recordFields.push({
                            label: columnLabelList[index] ?? key,
                            fieldName: key,
                            value: this.convertBoolean(rawValue),
                            isFirst: index === 0
                        });
                    }
                });
                const title = recordFields[0]?.value ?? '';
                const link = this.buildRecordLink(dataRecord);
                let rowClass = 'slds-hint-parent';
                if (isInactive) {
                    rowClass += ' inactiveRow';
                } else {
                    rowClass += ' row';
                }
                returnRecords.push({
                    recordFields: recordFields,
                    popoverFields: this._computePopoverFields(dataRecord),
                    popoverTitle: title,
                    popoverIcon: this.iconToUse,
                    Id: dataRecord.Id,
                    ContactId: this.resolve('ContactId', dataRecord) || dataRecord.ContactId,
                    isInactive: isInactive,
                    rowClass: rowClass,
                    title: title,
                    link: link
                });
            });
        }
        //Sorting records, inactive comes last
        returnRecords.sort((a, b) => {
            if (a.isInactive === b.isInactive) {
                return 0;
            }
            return a.isInactive ? 1 : -1;
        });
        return returnRecords;
    }

    // Build the card title with record count
    get cardTitle() {
        const numRecords = this.relatedRecords ? this.relatedRecords.length : 0;
        return `${this.listTitle} (${numRecords})`;
    }

    get headerBackground() {
        if (this.isMobile) {
            return 'background-color: white;';
        }
        return this.headerColor ? `background-color: ${this.headerColor};` : '';
    }

    // Prepare column labels array for rendering the header row
    get fieldLabels() {
        let labels = this.columnLabels ? this.columnLabels.replace(/\s/g, '').split(',') : [];
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
        if (this.relatedObjectApiName === 'AccountContactRelation' && !combined.includes('ContactId')) {
            combined.push('ContactId');
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

    _computePopoverFields(dataRecord) {
        if (!this.objectInfo || !this.objectInfo.data) {
            return [];
        }
        const fieldsToShow = (this.apexFieldList || []).filter((f) => f !== 'ContactId' && f !== 'Id');
        return fieldsToShow.map((fieldApiName) => {
            let fieldLabel;
            if (fieldApiName.includes('.')) {
                const [relationship, childField] = fieldApiName.split('.');
                if (this.relatedObjectMetadata?.[relationship]?.[childField]) {
                    fieldLabel = this.relatedObjectMetadata[relationship][childField].label;
                } else {
                    fieldLabel = childField;
                }
            } else {
                fieldLabel = this.objectInfo.data.fields[fieldApiName]?.label || fieldApiName;
            }
            let rawValue = this.resolve(fieldApiName, dataRecord);
            if (
                fieldApiName === 'TeamMemberRole' &&
                this.teamMemberRoleMapping &&
                this.teamMemberRoleMapping[rawValue]
            ) {
                rawValue = this.teamMemberRoleMapping[rawValue];
            }
            return {
                apiName: fieldLabel,
                value: this.convertBoolean(rawValue)
            };
        });
    }

    get iconToUse() {
        return this.iconName && this.iconName.trim() !== '' ? this.iconName : this.iconNamePopover;
    }

    convertBoolean(val) {
        if (val === true || String(val).toLowerCase() === 'true') {
            return 'Ja';
        } else if (val === false || String(val).toLowerCase() === 'false') {
            return 'Nei';
        }
        return val;
    }
    get isMobile() {
        return FORM_FACTOR === 'Small';
    }
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }
    get ariaHidden() {
        return !this.isExpanded;
    }
}
