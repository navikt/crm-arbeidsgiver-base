import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldValue from '@salesforce/apex/CustomNotificationController.getFieldValue';

export default class CustomNotification extends LightningElement {
    @api title;
    @api field;
    @api variant;
    @api icon;
    @api recordId;

    @track message;
    @track mainCss = 'slds-notify slds-notify_alert slds-theme_alert-texture round ';
    @track titleCss = 'slds-text-title_caps slds-var-p-right_large ';

    connectedCallback() {
        if (this.variant === 'error') {
            this.mainCss = this.mainCss.concat('slds-theme_error');
            this.titleCss += 'slds-text-color_inverse';
        } else if (this.variant === 'info') {
            this.mainCss = this.mainCss.concat('slds-theme_info');
            this.titleCss += 'slds-text-color_inverse';
        } else {
            // warning as fallback
            this.mainCss = this.mainCss.concat('slds-theme_warning');
        }
    }

    @wire(getFieldValue, { recordId: '$recordId', field: '$field' })
    deWire(result) {
        if (result.data) {
            this.message = result.data;
            this.showNotification();
        }
    }
}