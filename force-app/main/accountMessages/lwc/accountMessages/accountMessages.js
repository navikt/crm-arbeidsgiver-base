import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/AccountMessagesController.getData';
import { getRecord } from 'lightning/uiRecordApi';

export default class AccountMessages extends LightningElement {
	@api recordId;
	@track accountHistory;
	display = false;

	connectedCallback() {
		this.loadData();
	}
	loadData() {
		getData({ recordId: this.recordId })
			.then(result => {
				this.accountHistory = result;
				this.error = undefined;
				if (result.length > 0) {
					this.display = true;
				}
			})
	}
}