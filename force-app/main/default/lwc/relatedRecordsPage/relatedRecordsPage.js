/*
Use this component to display related records in a Lightning Web Component (LWC).
 * This component fetches related records based on the provided configuration
 * and displays them in a responsive data table format.
 *
 * @component
 * @example
 * <c-related-records-page></c-related-records-page>
 * 
 * Example: Navigation til component and set parameters:
 Bruk i LWC: Ved navigasjon:
this[NavigationMixin.Navigate]({
  type: 'standard__component',
  attributes: {
    componentName: 'c__relatedRecordPage'
  },
  state: {
    c__configKey: 'AccountContract',
    c__additionalFilter: 'TAG_Type_Partner__c = \'Strategisk Partner\'',
    c__parentRecordId: '001RR00000bhWZ8YAM',
    c__isMobile: true
  }
});

https://energy-customization-5209.scratch.lightning.force.com
/lightning/cmp/c__relatedRecordsPage?c__object=JobPosting__c&c__col=Name,Is_My_Region__c,Createddate&c__id=001QI00000Zb8nHYAR&c__rf=Account__c&c__fv=Status__c%3D%22ACTIVE%22

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