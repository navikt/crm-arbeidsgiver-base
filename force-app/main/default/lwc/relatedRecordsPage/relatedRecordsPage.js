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
    c__configKey: 'AccountContacts'
  }
});
*/

import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import getConfig from '@salesforce/apex/RelatedListConfigController.getConfig';
export default class RelatedRecordsPage extends LightningElement {
   
    // private properties
    columns = ['Name', 'CreatedDate', 'Email', 'Phone','MailingAddress']; // Fields to return from database
    filter = 'CreatedDate < TODAY'; // Query filter
    columnsConfig = [];
    relationField = 'AccountId';  // Field API name on related object that contains reference ID to the parent
    parentRelationField = 'Id'; // Field API name on parent object that contains the reference ID from "relationField"
    parentObjectApiName = 'Account'; // sObject API name of the parent
    

    // Get public properties from url
    @wire(CurrentPageReference)
    currentPageRef;
    // The key used to identify the configuration. i.e. configKey = 'Account_Contacts';
    get configKey() { 
        return this.currentPageRef.state.c__configKey;
    }

    // The record on the parent side of the lookup relationship. i.e. parentRecordId = '001QI00000YZE7PYAX';
    get parentRecordId() { 
        return this.currentPageRef.state.c__parentRecordId;
    }
    // sObject API name on the related object. i.e. relatedObjectApiName = 'Contact';  
    get relatedObjectApiName() {
        return this.currentPageRef.state.c__relatedObjectApiName;
    }
    // Specify layout type
    get isMobile() {
       // If not provided in url it should be initialize directly: isMobile = window.innerWidth <= 768;
    if (!this.currentPageRef.state.c__isMobile) {
        return window.innerWidth <= 768;
    }
       return this.currentPageRef.state.c__isMobile;
    }


    @wire(getConfig, { configKey: '$configKey' })
    config({ error, data }) {
        if (data) {
            console.log('Config data:', JSON.stringify(data, null, 2));
            this.columns = data.columns;
            this.filter = data.filter;
            this.columnsConfig = data.columnsConfig;
            this.relationField = data.relationField;
            this.parentRelationField = data.parentRelationField;
            this.parentObjectApiName = data.parentObjectApiName;
            this.relatedObjectApiName = data.relatedObjectApiName;
        } else if (error) {
            console.error('Error fetching config:', error);
        }
    }
    

    connectedCallback() {
        try {
            // Simulate an asynchronous operation
            this.initializeComponent()
                .then(() => {
                    console.log('Component initialized successfully');
                })
                .catch((error) => {
                    this.handleError('Error during initialization', error);
                });
        } catch (error) {
            this.handleError('Unexpected error in connectedCallback', error);
        }
    }

    async initializeComponent() {
        // Example of an asynchronous operation
        return new Promise((resolve, reject) => {
            // Simulate success or failure
            const isSuccess = true; // Change to false to simulate an error
            if (isSuccess) {
                resolve();
            } else {
                reject(new Error('Initialization failed'));
            }
        });
    }

    handleError(message, error) {
        console.error(`${message}:`, error);
    }
}