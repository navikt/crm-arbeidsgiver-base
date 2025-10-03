/*
Component to apply custom CSS styles to override default Salesforce styling.
Usage:
1. Deploy the component to org.
2. Add the component to Lightning Record Page via the Lightning App Builder.
3. Pass your custom CSS styles as a string to the `cssInput` property.

Example to replace default styling on dynamic highlights panel with compact styling:
Default:
.slds-page-header {
    padding-block: var(--slds-g-spacing-var-block-4);
}
.slds-page-header__detail-row {
    margin-block: var(--slds-g-spacing-var-block-4) calc(var(--slds-g-spacing-var-block-4) * -1);
    padding: var(--slds-g-spacing-var-inline-4);
}
Compact:
.slds-page-header {
    padding-block: var(--slds-g-spacing-var-block-4) 0 !important;
}
.slds-page-header__detail-row {
    margin-block: 0 !important;
    padding-top: 0 !important;
    padding-bottom: 0 !important;
}

*/

import { LightningElement, api } from 'lwc';

export default class CustomPageStyle extends LightningElement {
    @api cssInput;
    connectedCallback() {
        this.applyStyling();
    }

    applyStyling() {
        const style = document.createElement('style');
        style.innerText = this.cssInput;
        document.head.appendChild(style);
    }
}
