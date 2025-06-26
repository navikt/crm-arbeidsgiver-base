import { LightningElement, api, wire, track } from 'lwc';
//import { getListInfoByName } from "lightning/uiListsApi";
import { getListRecordsByName } from 'lightning/uiListsApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';


export default class OpportunityListView extends NavigationMixin(LightningElement) {
    @api previewRecords = 4; // Maks antall records å vise
    @api listViewApiName = 'TAG_Mine_pne_muligheter'; // List view navn for å hente records
    @api objectApiName = 'CustomOpportunity__c';
    @api helpText = 'Dette er en hjelpetekst for komponentet.'; // Hjelpetekst for komponentet
    @api titleText = 'Mine muligheter'; // Tittel for komponentet
    @api iconName = 'custom:custom14'; // Standard ikon for muligheter

    error;
    records = [];
    displayColumns;
    listReference;    
    isRefreshing=true;
    wiredListViewRecordsResult;

    nextPageToken; // For å håndtere neste side
    count;


    fieldsTest = [
        'CustomOpportunity__c.TAG_Link__c',
        'CustomOpportunity__c.Account__r.Name',
        'CustomOpportunity__c.TAG_Age__c'
    ];

    titleField = 'TAG_Link__c';
    detailFields = ['Account__r.Name'];
    warningField = 'TAG_Age__c'; // Felt som brukes for å vise advarsel

    @track recordLevelActions = [{ id: 'record-edit-1', label: 'Edit', value: 'edit'}];
    @track objectLevelActions = [{ id: 'object-new-1', label: 'New', value: 'new' }];

    
    

    // 2. Hent records når listViewId og felter er tilgjengelige
    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$fieldsTest',
        pageSize: '$previewRecords'
    })
    wiredListViewRecords(result) {
        this.wiredListViewRecordsResult = result; // Lagre resultatet for senere oppdatering
        if (result.data) {
            console.log('listRecords data:', JSON.stringify(result.data, null, 2));
            this.records = result.data.records.map((record) => {
                let title = record.fields[this.titleField]
                    ? this.sanitizeHtml(record.fields[this.titleField].value)
                    : null;
                let recordFields = [];
                this.detailFields.forEach((field) => {
                    if (this.isRelatedField(field)) {
                        const value = this.getNestedFieldValue(record, field);
                        recordFields.push(value);
                    } else {
                        const value = record.fields[field] ? record.fields[field].value : null;
                        recordFields.push(value);
                    }
                });
                let listRecord = {
                    id: record.id,
                    title: title,
                    titleLink: '/lightning/r/' + record.apiName + '/' + record.id + '/view',
                    detailLine: recordFields.toString(),
                    showWarning:
                        record.fields[this.warningField] && record.fields[this.warningField].value > 5 ? true : false
                };
                return listRecord;
            });
            this.nextPageToken = result.data.nextPageToken;   
            this.count = result.data.count;            
            this.error = undefined;            
            this.isRefreshing = false;
        } else if (result.error) {
            console.error('Feil ved henting av records:', result.error);
        }
    }

    
    get hasMoreRecords() {
        return this.nextPageToken === null ? false : true;
    }

    get listViewUrl() {
        return `/lightning/o/${this.objectApiName}/list?filterName=${this.listViewApiName}`;
    }

    get cardTitle(){
        if(this.isRefreshing) {
            return this.titleText + ' (...)';
        }
        if(this.hasMoreRecords){
            return this.titleText + ' ('+ this.count + '+)';
        } 
        return this.titleText + ' (' + this.count + ')';
    }


    handleRecordLevelAction(event) {
        // Get the value of the selected action
        const selectedItemValue = event.detail.value;
        const recordId = event.target.dataset.recordId; // Hent recordId fra data attributtet
        console.log('Valgt handling:', selectedItemValue, 'for recordId:', recordId);
        if (selectedItemValue === 'edit') {
            // Håndter redigeringshandling
            this.navigateToRecordEdit(recordId, this.objectApiName);
        } else {
            console.warn('Ukjent handling valgt:', selectedItemValue);
        }
    }
    handleObjectLevelAction(event) {
        // Get the value of the selected action
        const selectedItemValue = event.detail.value;
        if (selectedItemValue === 'new') {
            this.navigateToRecordNew(this.objectApiName);
        } else {
            console.warn('Ukjent handling valgt:', selectedItemValue);
        }
    }

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
            }
        });
    }

    
    navigateToListView(event) {        
        console.log('Naviger til list view');
        event.preventDefault();
        this[NavigationMixin.Navigate](
            {
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: this.listViewApiName 
                }
            }
        );
    }

    navigateToRecord(event) {
        console.log('Naviger til record');
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        console.log('Valgt recordId:', recordId);
        this[NavigationMixin.Navigate]({
             type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
               objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });

    }

    sanitizeHtml(input) {
        return input?.replace(/<[^>]+>/g, '') ?? '';
    }
    isRelatedField(fieldName) {
        return fieldName.includes('__r.');
    }
    getNestedFieldValue(record, fieldName) {
        const parts = fieldName.split('.');

        let current = record.fields;

        for (const part of parts) {
            const field = current?.[part];
            if (!field) return '';

            // Hvis vi er på siste del
            if (part === parts.at(-1)) {
                return field.displayValue ?? field.value ?? '';
            }

            // Gå ett nivå dypere
            current = field.value?.fields;
            if (!current) return '';
        }

        return '';
    }

    /*
                data.fields.forEach(dataField => {                  
                    let fieldName = dataField.split('.').pop(); // Get the field name after the last dot                    
                    
                    let newField = { 
                        fieldName: fieldName, 
                        value: record.fields[fieldName] ? record.fields[fieldName].value : null, 
                        label: this.displayColumns[fieldName] ? this.displayColumns[fieldName].label : fieldName
                    }; // Create field object
                    result.fields.push(newField); // Add field object to fields array
                });*/
    /*
*



    get listRecordsfields(){        
        // only get 2 first fields
        if(this.displayColumns && this.displayColumns.length > 2){
            let fields = this.displayColumns.slice(0, 2).map(displayColumn => this.objectApiName+'.'+displayColumn.fieldApiName);
            console.log('fields:', JSON.stringify(fields, null, 2));
            return fields;
        }
        return []; 
    }


    // 1. Hent list view metadata
    @wire(getListInfoByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName'
    })
    listInfo({ data, error }) {
        if (data) {
            console.log('listInfo data:', JSON.stringify(data));
            this.displayColumns = data.displayColumns.reduce((map, obj) => {
                map[obj.fieldApiName] = obj;
                return map;
            }, {});
            this.listReference = data.listReference;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            
            console.error('Feil ved henting av list view-info:', error);
        }
    }

*/
}
