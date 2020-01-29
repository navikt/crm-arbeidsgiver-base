import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'


export default class TagActivityTimelineItem extends NavigationMixin(LightningElement) {

	@api row;
	@api recordId;
	@api labels;
	@api momemt;

	@track expanded = false;
	@track className = "slds-timeline__item_expandable";

	connectedCallback() {
		if (this.row.theme.sldsTimelineItem != null) {
			this.className = "slds-timeline__item_expandable " + this.row.theme.sldsTimelineItem;
		}
	};

	get getDateFormat() {
		try {
			while (moment !== undefined) {
				return moment(this.row.record.dateValueDb).fromNow();
			} // TODO add error after x seconds
			// TODO remove try
		} catch (error) {

		}
	}

	get isTask() {
		return this.row.record.sObjectKind === "Task";
	}

	openRecord() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.row.record.recordId,
				objectApiName: this.row.record.sObjectType,
				actionName: 'view'
			}
		});
	}

	toggleDetailSection() {
		this.expanded = !this.expanded;
	}

	openUser(event) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: event.target.dataset.id,
				objectApiName: 'User',
				actionName: 'view'
			}
		});
	}

	get isAssigneeAUser() {
		return "assigneeId" in this.row.record;
	}

	get isRelatedUserAUser() {
		return "relatedUserId" in this.row.record;
	}
}