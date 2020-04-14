import { LightningElement, api, wire, track } from 'lwc';
import getAccountHistory from '@salesforce/apex/AccountMessagesController.getAccountHistory';
import getParentAccountHistory from '@salesforce/apex/AccountMessagesController.getParentAccountHistory';
import { getRecord } from 'lightning/uiRecordApi';


export default class AccountMessages extends LightningElement {
	@api recordId;
	accountHistory;
	parentAccountHistory;


	connectedCallback() {
		this.loadAccountHistory();
		this.loadParentAccountHistory();

	}

	loadAccountHistory() {
		getAccountHistory({ recordId: this.recordId })
			.then(result => {
				this.accountHistory = result;
				this.error = undefined;
			})
			.catch(error => {
				this.error = error;
				this.accountHistory = undefined;
			});
	}

	loadParentAccountHistory() {
		getParentAccountHistory({ recordId: this.recordId })
			.then(result => {
				this.parentAccountHistory = result;
				this.error = undefined;
			})
			.catch(error => {
				this.error = error;
				this.parentAccountHistory = undefined;
			});
	}

}