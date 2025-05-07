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

https://energy-customization-5209.scratch.lightning.force.com/lightning/cmp/c__relatedRecordPage?c__configKey=AccountContract&c__parentRecordId=001RR00000bhWZ8YAM
*/

import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import getConfig from '@salesforce/apex/RelatedListConfigController.getConfig';
export default class RelatedRecordsPage extends LightningElement {
   
    // private properties
    relatedObjectApiName; // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
    columns; // Fields to return from database
    filter; // Query filter
    columnsConfig;
    relationField;  // Field API name on related object that contains reference ID to the parent
    parentRelationField; // Field API name on parent object that contains the reference ID from "relationField"
    parentObjectApiName; // sObject API name of the parent
    

    parentRecordId;
    configKey;
    isMobile;
    additionalFilter; 
   
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageRef = currentPageReference;

        this.parentRecordId = currentPageReference.state.c__parentRecordId;
        this.configKey=currentPageReference.state.c__configKey;
        this.additionalFilter=currentPageReference.state.c__additionalFilter;
        if (!currentPageReference.state.c__isMobile) {
            this.isMobile = window.innerWidth <= 768;
        } else{
            this.isMobile = currentPageReference.state.c__isMobile;
        }
        
        if (currentPageReference?.state?.c__configKey) {           
            this.loadConfig();
        }       
        
        console.log('Ran setCurrentPageReference: ' + JSON.stringify(this.currentPageRef));
    }
    
    loadConfig() {
        getConfig({ configKey: this.configKey })
            .then(result => {
                
                console.log('Config data:', JSON.stringify(result, null, 2));
            this.columns = result.columns;
            this.filter = this.combineFilters(result.filter, this.additionalFilter);            
            this.columnsConfig = result.columnsConfig;
            this.relationField = result.relationField;
            this.parentRelationField = result.parentRelationField;
            this.parentObjectApiName = result.parentObjectApiName;
            this.relatedObjectApiName = result.relatedObjectApiName;
              
            })
            .catch(error => {
                console.error('Error loading config:', error);
            });
    }


    combineFilters(f1, f2) {
        console.log('Combining filters:', f1, f2);
        if (f1 && f2) {
            return `${f1} AND ${f2}`;
        } else if (f1) {
            return f1;
        } else if (f2) {
            return f2;
        }
        return null;

    }

    connectedCallback() {
        console.log('RelatedRecordsPage connectedCallback');
        
    }

}