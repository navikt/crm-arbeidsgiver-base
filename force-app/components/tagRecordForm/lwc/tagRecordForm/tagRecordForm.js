import { LightningElement, api, track } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';
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
        // Toggle open status
        this.open = !this.open;
        // Log that form was opened by user
        if(this.open && !this.isDefaultOpen){
            this.logToAmplitude();
        }
    }

    logToAmplitude(){
        const amplitudeType = 'Field section "'+this.label+'" opened';
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: amplitudeType});      
    }
}
