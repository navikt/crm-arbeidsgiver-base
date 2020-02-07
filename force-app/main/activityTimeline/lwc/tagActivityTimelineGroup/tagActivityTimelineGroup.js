import { LightningElement, api, track } from 'lwc';

export default class TagActivityTimelineGroup extends LightningElement {

	@api group;
	@api labels;
	@api amountOfRecords;
	@api amountOfRecordsToLoad;

	@track amount;

	connectedCallback() {
		this.amount = this.amountOfRecords;
	}

	get showViewMore() {
		return this.amount < this.group.models.length;
	}

	viewMore() {
		this.amount += this.amountOfRecordsToLoad;
	}

	viewAll() {
		this.amount = this.group.models.length;
	}
}