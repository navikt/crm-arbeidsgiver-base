import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/AccountMessagesController.getData';
import { getRecord } from 'lightning/uiRecordApi';


export default class AccountMessages extends LightningElement {
	@api recordId;
	@track isBankrupt;
	@track isInLiquidation;
	@track isInForcedSettlementOrResolution;

	accountHistory;
	parentAccountHistory;


	connectedCallback() {
		this.loadData();
	}
	loadData() {
		getData({ recordId: this.recordId })
			.then(result => {
				this.accountHistory = result;
				if (result) {
					this.isBankrupt = result.isBankrupt;
					this.isInLiquidation = result.isInLiquidation;
					this.isInForcedSettlementOrResolution = result.isInForcedSettlementOrResolution;
				}
				this.error = undefined;

			})
			.catch(error => {
				this.error = error;
				this.parentAccountHistory = undefined;

			})
	}
}