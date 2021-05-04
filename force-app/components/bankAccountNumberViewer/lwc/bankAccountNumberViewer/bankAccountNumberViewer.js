import { LightningElement, wire, api } from 'lwc';
import getBankAccountNumber from '@salesforce/apex/BankAccountController.getBankAccountNumber';

export default class BankAccountNumberViewer extends LightningElement {
    @api recordId;

    isClosed = false;

    @wire(getBankAccountNumber, { recordId: '$recordId' })
    accountNumber;

    openClose() {
        if (this.isClosed) {
            this.template.querySelector('.slds-section').classList.add('slds-is-open');
            this.isClosed = false;
        } else {
            this.template.querySelector('.slds-section').classList.remove('slds-is-open');
            this.isClosed = true;
        }
    }
}
