import { LightningElement, api } from 'lwc';

export default class RelatedRecordsPage extends LightningElement {
    columns = ['Name', 'CreatedDate', 'Email', 'Phone','MailingAddress']; // SELECT fields
    relatedObjectApiName = 'Contact';  // from 
    filter = 'CreatedDate < TODAY'; // F.eks. WHERE-klausul eller feltverdier
     // query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';
    relationField = 'AccountId'; 
    parentRelationField = 'Id';
    parentObjectApiName = 'Account';
    parentRecordId = '001QI00000YZE7PYAX';

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