import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'


export default class TagActivityTimelineItem extends NavigationMixin(LightningElement) {

	@api row;
	@api recordId;
	@api labels;
	@api amount;
	@api index;

	@track expanded = false;
	@track timelineColor = "slds-timeline__item_expandable";

	connectedCallback() {
		if (this.row.theme.sldsTimelineItemColor != null) {
			this.timelineColor = "	background-color: #" + this.row.theme.sldsTimelineItemColor + ";";
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

	get showRow() {
		return this.index < this.amount;
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