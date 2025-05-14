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
export default class RelatedRecordsPage extends LightningElement {
   
    // private properties
    columns; // Fields to return from database
    objectApiName; // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
    filter; // Query filter
    relationField;  // Field API name on related object that contains reference ID to the parent
    parentRecordId;
    
    formFactor;
   

    @wire(CurrentPageReference)
    setPageRef(pageRef) {

        this.objectApiName = pageRef?.state?.c__object;
        this.parentRecordId = pageRef?.state?.c__id;
        this.relationField = pageRef?.state?.c__rf;
        this.filter=pageRef?.state?.c__fv; 
        this.columns=pageRef?.state?.c__col; // Split the columns string into an array
        this.formFactor = pageRef?.state?.c__size;  
        if(!pageRef?.state?.c__size){
            if (window.innerWidth <= 768) {
                //this.formFactor  = 'small';
             } else{
                //this.formFactor  = 'large';
             }
        }  
    }


    connectedCallback() {
        /*
        console.log('RelatedRecordsPage connectedCallback');
        this.configKey = this.currentPageRef.state.c__configKey;
        this.parentRecordId = this.currentPageRef.state.c__parentRecordId;       
        this.additionalFilter=this.currentPageRef.state.c__additionalFilter;        
        if (!this.currentPageRef.state.c__isMobile) {
            this.isMobile = window.innerWidth <= 768;
        } else{
            this.isMobile = this.currentPageRef.state.c__isMobile;
        }        
        if (this.configKey && this.parentRecordId) {           
            this.loadConfig();
        }       
            */ 
    }


    


}