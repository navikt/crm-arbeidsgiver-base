import { LightningElement, api, track } from 'lwc';
export default class TagRecordForm extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api label;
    @api fields;
    @api twoColumns;
    @api isDefaultOpen;
    @api readOnly;

    @track fieldArray = [];
    @track open;

    // run the getter when the component is connected to the DOM
    connectedCallback() {
        try {
            if (this.fields) {
                this.fieldArray = this.fields.split(',').map((field) => field.trim());
            } else {
                console.error('fields property is undefined or empty');
            }

            if (typeof this.open === 'undefined') {
                this.open = this.isDefaultOpen;
            }
        } catch (error) {
            console.error('Error in connectedCallback: ' + error.message);
        }
    }

    get sectionClass() {
        return this.open ? 'slds-section slds-is-open' : 'slds-section';
    }
    get mode() {
        return this.readOnly ? 'readonly' : 'view';
    }
    get density() {
        return 'Comfy';
    }
    get columns() {
        return this.twoColumns ? '2' : '1';
    }

    handleClick() {
        this.open = !this.open;
    }
}
