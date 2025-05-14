import { LightningElement, api, wire } from 'lwc';
import getRecords from '@salesforce/apex/RelatedListConfigController.getRecords';
export default class RelatedRecordsContainer extends LightningElement {
    @api columns;
    @api objectApiName;
    @api filter;
    @api relationField;
    @api parentId;
    @api formFactor; // Small, Medium, Large
    
    @api parentRelationField;
    @api parentObjectApiName;
    get isMobile(){
        if(this.formFactor){return this.formFactor;}
        return window.innerWidth <= 768; // Initialize directly
     }

    records = [];
    error;
   
   //@api columnsConfig;
    objectInfo;
    isObjectInfoLoaded = false;

    // Lifecycle method to handle initialization
    connectedCallback() {
        console.log('connectedCallback initialized');
        console.log('Parent ID:', this.parentId);
        console.log('Related Object API Name:', this.objectApiName);
        console.log('Columns:', this.columns);
        console.log('Filter:', this.filter);
        console.log('Relation Field:', this.relationField);
        console.log('filter:', this.filter);
        console.log('Form Factor:', this.formFactor);
        this.getList();
    }

   

    // Fetch related records
    getList() {        
        getRecords({
            columns: this.columns,
            parentRecordId: this.parentId,
            objectApiName: this.objectApiName,
            relationshipField: this.relationField,
            filter: this.filter
        })
            .then((data) => {
                this.records = data && data.length > 0 ? data : [];
                console.log('Records returned:', JSON.stringify( this.records));
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
        if(this.records && this.records.length > 0){
            
            const columns = this.records[0].fields.map((field) => {
                return {
                    label: field.label,
                    fieldName: field.fieldName,
                    type: field.type,
                    typeAttributes: field.typeAttributes,
                    sortable: false,
                    cellAttributes: {
                       alignment: 'left'
                    },
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
        if(this.records && this.records.length > 0){
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


    // Centralized error handling
    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
        this.error = error;
    }
}
