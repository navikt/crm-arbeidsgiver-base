import { LightningElement, api, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/TAG_RelatedListController.getRelatedList';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RelatedRecordsContainer extends LightningElement {
    @api columns;
    @api relatedObjectApiName;
    @api filter;
    @api relationField;
    @api parentRelationField;
    @api parentObjectApiName;
    @api parentId;
    @api isMobile;

    records = [];
    error;
   
    columnsConfig = [];
    objectInfo;
    isObjectInfoLoaded = false;

    // Lifecycle method to handle initialization
    connectedCallback() {
        console.log('connectedCallback initialized');
    }

    // Reactive wire to fetch object info
    @wire(getObjectInfo, { objectApiName: '$relatedObjectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
            this.isObjectInfoLoaded = true;
            this.generateColumnsConfig();
            this.getList();
        } else if (error) {
            this.handleError('Error loading object info', error);
        }
    }

    // Fetch related records
    getList() {
        if (!this.isObjectInfoLoaded) {
            console.warn('getList skipped: objectInfo not loaded yet');
            return;
        }
        getRelatedList({
            fieldNames: this.columns,
            parentId: this.parentId,
            objectApiName: this.relatedObjectApiName,
            relationField: this.relationField,
            parentRelationField: this.parentRelationField,
            parentObjectApiName: this.parentObjectApiName,
            filterConditions: this.filter
        })
            .then((data) => {
                this.records = data && data.length > 0 ? data : [];
                console.log('Records returned:', this.records);
            })
            .catch((error) => {
                this.handleError('Error retrieving related records', error);
            });
    }

    // Generate column configuration dynamically
    generateColumnsConfig() {
        if (!this.objectInfo || !this.columns) return;

        this.columnsConfig = this.columns
            .map((fieldName) => {
                const fieldMeta = this.objectInfo.fields[fieldName];
                if (!fieldMeta) return null;

                return {
                    label: fieldMeta.label,
                    fieldName: fieldName,
                    type: this.mapFieldType(fieldMeta.dataType)
                };
            })
            .filter(Boolean); // Remove null values
        console.log('Generated columnsConfig:', this.columnsConfig);
    }

    // Map field data types to LWC types
    mapFieldType(dataType) {
        const fieldTypeMap = {
            Phone: 'phone',
            Email: 'email',
            Date: 'date',
            DateTime: 'datetime',
            Currency: 'currency',
            Double: 'double',
            Integer: 'number',
            Boolean: 'boolean',
            Picklist: 'text',
            Address: 'address'
        };
        return fieldTypeMap[dataType] || 'text';
    }

    // Centralized error handling
    handleError(message, error) {
        console.error(`${message}:`, error);
        this.error = error;
    }
}
