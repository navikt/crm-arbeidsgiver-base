/*
Use this component to display related records in a Lightning Web Component (LWC).
 * This component fetches related records based on the provided configuration
 * and displays them in a responsive data table format.
 *
CustomOpportunity__c
/lightning/cmp/c__relatedRecordsPage?c__object=CustomOpportunity__c&c__col=Name,TAG_Is_my_NAV_region__c,TAG_IA_Service_End__c,Createddate&c__id=001QI00000Zb8nHYAR&c__rf=Account__c&c__fv=Createddate<TODAY

*/

import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import getConfig from '@salesforce/apex/RelatedListConfigFactory.getConfig';

export default class RelatedRecordsPage extends LightningElement {
    // private properties
    columns; // Fields to return from database
    objectApiName; // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
    filter; // Query filter
    relationField;  // Field API name on related object that contains reference ID to the parent
    parentRecordId;
    isConfigLoaded = false; // Flag to track if config is loaded

    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        this.objectApiName = pageRef?.state?.c__object;
        this.parentRecordId = pageRef?.state?.c__id;
        this.relationField = pageRef?.state?.c__rf;
        this.filter = pageRef?.state?.c__fv;
    }

    connectedCallback() {
        if (this.objectApiName) {
            this.getColumns();
        }
    }

    getColumns() {
        getConfig({ objectApiName: this.objectApiName })
            .then((data) => {
                this.columns = data && data.length > 0 ? data : [];
                this.isConfigLoaded = true; // Mark config as loaded
                console.log('Columns returned:', JSON.stringify(this.columns));
            })
            .catch((error) => {
                this.handleError('Error retrieving related records', error);
            });
    }

    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
}