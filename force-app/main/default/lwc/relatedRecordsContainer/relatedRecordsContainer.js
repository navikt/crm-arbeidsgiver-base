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
        console.log('Parent Relation Field:', this.parentRelationField);
        console.log('Parent Object API Name:', this.parentObjectApiName);
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


    // Centralized error handling
    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
        this.error = error;
    }
}
