import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/AccountMessagesController.getData';
import getDeletedDate from '@salesforce/apex/AccountMessagesController.getDeletedDate';
import { NavigationMixin } from 'lightning/navigation';

export default class AccountMessages extends NavigationMixin(LightningElement) {
    @api recordId;
    @track display = false;
    @track accountId;
    @track field;
    @track displayDeleted = false;
    @track deletedDate;

    connectedCallback() {
        this.loadData();
        this.loadDeletedDate();
    }
    loadData() {
        getData({ recordId: this.recordId }).then((result) => {
            if (result) {
                this.display = true;
                this.field = result.field;
                this.accountId = result.accountId;
            }
        });
    }

    loadDeletedDate() {
        getDeletedDate({ recordId: this.recordId }).then((date) => {
            if (date) {
                this.deletedDate = date;
                this.displayDeleted = true;
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
