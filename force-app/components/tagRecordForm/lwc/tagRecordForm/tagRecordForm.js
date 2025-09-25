import { LightningElement, api, track } from 'lwc';
import { publishToAmplitude } from 'c/amplitude';

import FORM_FACTOR from '@salesforce/client/formFactor';
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

    sectionId='';

    // CSS to mimic standard field section component
    CARD_STYLE_LARGE='slds-card__body slds-card__body_inner';
    SECTION_STYLE_LARGE = 'slds-section';
    SECTION_STYLE_LARGE_OPEN = this.SECTION_STYLE_LARGE + ' slds-is-open';
    H3_STYLE_LARGE = 'slds-section__title slds-p-around_xx-small slds-theme_shade h3-large';
    BUTTON_STYLE_LARGE = 'slds-button slds-section__title-action';
    // CSS to mimic standard field section component in mobile app
    CARD_STYLE_SMALL=''; // No style on mobile
    SECTION_STYLE_SMALL = this.SECTION_STYLE_LARGE + ' section-small';
    SECTION_STYLE_SMALL_OPEN = this.SECTION_STYLE_SMALL + ' slds-is-open';
    H3_STYLE_SMALL = this.H3_STYLE_LARGE + ' h3-small';
    BUTTON_STYLE_SMALL = this.BUTTON_STYLE_LARGE + ' button-small';
   
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
            this.sectionId = this.label.replace(/\s+/g, '-').toLowerCase() + '-' + Math.random().toString(36).substring(2, 15);
        } catch (error) {
            console.error('Error in connectedCallback: ' + error.message);
        }
    }

    get cardStyle(){
        return this.isMobile ? this.CARD_STYLE_SMALL : this.CARD_STYLE_LARGE;
    }
    get sectionStyle() {
        if (this.isMobile) {
            return this.open ? this.SECTION_STYLE_SMALL_OPEN : this.SECTION_STYLE_SMALL;
        } 
        return this.open ? this.SECTION_STYLE_LARGE_OPEN : this.SECTION_STYLE_LARGE;
    }
    
    get h3Style(){
        return this.isMobile ? this.H3_STYLE_SMALL : this.H3_STYLE_LARGE;
        
    }
    get buttonStyle(){
        return this.isMobile ? this.BUTTON_STYLE_SMALL : this.BUTTON_STYLE_LARGE;
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

   handleClick(event) {
    console.log('before toggle: ' + this.open);
        let buttonid = event.currentTarget.dataset.buttonid;
        let currentsection = this.template.querySelector('[data-id="' + buttonid + '"]');
        console.log('currentsection: ' + currentsection);
         // Toggle open status
        this.open = !this.open;
        currentsection.className = this.sectionStyle;
        console.log('after toggle: ' + this.open);
        // Log that form was opened by user
        if (this.open && !this.isDefaultOpen) {
            this.logToAmplitude();
        }
    }

    logToAmplitude() {
        const amplitudeType = 'Field section "' + this.label + '" opened';
        this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
        publishToAmplitude(this.appName, { type: amplitudeType });
    }
    get ariaHidden(){
        return !this.open;
    }

     get isMobile() {
        return FORM_FACTOR === 'Small';
    }
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }
}
