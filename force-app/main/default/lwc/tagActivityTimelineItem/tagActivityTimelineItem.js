import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'

export default class TagActivityTimelineItem extends NavigationMixin(LightningElement) {

	@api title;
	@api object;
	@api type;
	@api dateValue;
	// @api expandedFieldsToDisplay;
	@api recordId;
	@track expanded;
	@api themeInfo;

	@track className = "slds-timeline__item_expandable";


	connectedCallback() {
		if (this.themeInfo.sldsTimelineItem != null) {
			this.className = "slds-timeline__item_expandable " + this.themeInfo.sldsTimelineItem;
		}
	};


	get objectThemeColor() {
		return `background-color: #444`;
	} get itemStyle() {
		return this.expanded ? "slds-timeline__item_expandable slds-is-open" : "slds-timeline__item_expandable";
	} get totalFieldsToDisplay() {
		return 2;
	} get isTask() {
		return this.object === "Task";
	} toggleDetailSection() {
		this.expanded = !this.expanded;
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

}