import { LightningElement, api, track } from 'lwc';
import getData from '@salesforce/apex/AccountMessagesController.getData';
import { NavigationMixin } from 'lightning/navigation';

export default class AccountMessages extends NavigationMixin(LightningElement) {
    @api recordId;
    @track display = false;
    @track accountId;
    @track field;
    @track deletedMessage;

    connectedCallback() {
        this.loadData();
    }
    loadData() {
        getData({ recordId: this.recordId }).then((result) => {
            if (result) {
                this.display = true;
                this.field = result.field;
                this.accountId = result.accountId;
                this.deletedMessage = result.deletedMessage;
            }
        });
    }

    openRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accountId,
                actionName: 'view'
            }
        });
    }
}
