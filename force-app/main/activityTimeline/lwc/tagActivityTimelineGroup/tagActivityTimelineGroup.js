import { LightningElement, api, track } from 'lwc';

export default class TagActivityTimelineGroup extends LightningElement {

	@api group;
	@api labels;
	@track amount = 3;

	renderedCallback() {
		if (this.group.models.length < 3) {
			this.amount = this.group.models.length;
		}
	}

	get showLoadMore() {
		return this.amount < this.group.models.length;
	}

	loadMore() {
		this.amount += 3;
	}
}