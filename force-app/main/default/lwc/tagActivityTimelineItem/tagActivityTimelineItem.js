import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'

export default class TagActivityTimelineItem extends NavigationMixin(LightningElement) {

	@api title;
	@api subtitle;
	@api object;
	@api type;
	@api dateValue;
	@api recordId;
	@api themeInfo;
	@track expanded = false;

	@track className = "slds-timeline__item_expandable";

	connectedCallback() {
		if (this.themeInfo.sldsTimelineItem != null) {
			this.className = "slds-timeline__item_expandable " + this.themeInfo.sldsTimelineItem;
		}
	};

	get isTask() {
		return this.object === "Task";
	}

	openRecord() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				objectApiName: this.object,
				actionName: 'view'
			}
		});
	}

	toggleDetailSection() {
		this.expanded = !this.expanded;
	}

}