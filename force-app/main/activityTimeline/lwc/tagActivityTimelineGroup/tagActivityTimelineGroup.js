import { LightningElement, api, track } from 'lwc';

export default class TagActivityTimelineGroup extends LightningElement {

	@api group;
	@api labels;
	@api amountOfRecords;
	@api amountOfRecordsToLoad;

	@track amount;
	@track empty = false;

	connectedCallback() {
		this.amount = this.amountOfRecords;
	}

	renderedCallback() {
		this.empty = this.group.models.length === 0;
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