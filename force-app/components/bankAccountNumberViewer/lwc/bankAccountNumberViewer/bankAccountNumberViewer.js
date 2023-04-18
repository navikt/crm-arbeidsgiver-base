import { LightningElement, wire, api,track } from 'lwc';
import getBankAccountNumber from '@salesforce/apex/BankAccountController.getBankAccountNumber';

export default class BankAccountNumberViewer extends LightningElement {
    @api recordId;
    @track iconname = 'utility:chevrondown';
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
    handleCopy(event) {
        const hiddenInput = document.createElement('input');
        const eventValue = event.currentTarget.value;
        hiddenInput.value = eventValue;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
        try {
            const successful = document.execCommand('copy');
            if (!successful) this.showCopyToast('error');
        } catch (error) {
            this.showCopyToast('error');
        }

        document.body.removeChild(hiddenInput);
    }

    openClose() {
        if (this.isClosed) {
            this.template.querySelector('.slds-section').classList.add('slds-is-open');
            this.isClosed = false;
            this.iconname = 'utility:chevrondown';
        } else {
            this.template.querySelector('.slds-section').classList.remove('slds-is-open');
            this.isClosed = true;
            this.iconname = 'utility:chevronright';
        }
    }

}
