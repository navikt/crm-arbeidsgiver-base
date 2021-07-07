import { LightningElement, wire, api } from 'lwc';
import getBankAccountNumber from '@salesforce/apex/BankAccountController.getBankAccountNumber';

export default class BankAccountNumberViewer extends LightningElement {
    @api recordId;

    isClosed = false;
    isLoading = true;
    style = '';
    text;

    @wire(getBankAccountNumber, { recordId: '$recordId' })
    deWire(result) {
        if (result.data) {
            if (result.data.isSuccess) {
                this.text = result.data.kontonr;
            } else {
                this.text = result.data.feilmelding;
            }
            this.isLoading = false;
        } else if (result.error) {
            this.text = result.error.body.message;
            this.isLoading = false;
        }
    }

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
