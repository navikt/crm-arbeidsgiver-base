import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/AccountMessagesController.getData';
import { getRecord } from 'lightning/uiRecordApi';


export default class AccountMessages extends LightningElement {
	@api recordId;
	@track accountHistory;
	parentAccountHistory;
	isBankrupt = false;
	isNotBankrupt = false;
	isInLiquidation = false;
	isInForcedSettlementOrResolution = false;
	list = [];


	connectedCallback() {
		this.loadData();
	}
	loadData() {
		getData({ recordId: this.recordId })
			.then(result => {
				this.accountHistory = result;
				this.error = undefined;

				console.log('result', result);
				for (let i = 0; i < result.length; i++) {

					let field = result[i].field;
					let isNew = result[i].isNew;

					if (field === 'isBankrupt' && isNew === true) {
						this.isBankrupt = true;
						this.eventDate = result[i].eventDate;
					} else if (field === 'isInLiquidation' && isNew === true) {
						this.isInLiquidation = true;
						this.eventDate = result[i].eventDate;
					} else if (field === 'isInForcedSettlementOrResolution' && isNew === true) {
						this.isInForcedSettlementOrResolution = true;
						this.eventDate = result[i].eventDate;
					}
					//this.eventDate = result[i].eventDate;
					/*this.isBankrupt = (field === 'isBankrupt');
					this.isInLiquidation = (field === 'isInLiquidation');
					this.isInForcedSettlementOrResolution = (field === 'isInForcedSettlementOrResolution');*/
				}
			})
			.catch(error => {
				this.error = error;
				this.accountHistory = undefined;

			})
	}
}