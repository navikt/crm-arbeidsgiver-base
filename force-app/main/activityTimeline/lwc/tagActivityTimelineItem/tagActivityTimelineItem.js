import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'

export default class TagActivityTimelineItem extends NavigationMixin(LightningElement) {

	@api row;
	@api recordId;
	@api labels;
	@api amount;
	@api index;
	@api period;

	@track expanded = false;
	@track timelineColor = "slds-timeline__item_expandable";

	connectedCallback() {
		if (this.row.theme.sldsTimelineItemColor != null) {
			this.timelineColor = "	background-color: #" + this.row.theme.sldsTimelineItemColor + ";";
		}
	};

	get getDateFormat() {

		// TODO mouseover to get relative fromNow()

		try {
			if (this.period === this.labels.upcoming || this.period === this.labels.overdue) {
				var settings = this.row.record.isDate ? {
					sameDay: '[' + this.labels.today + ']',
					nextDay: '[' + this.labels.tomorrow + ']',
					nextWeek: 'dddd',
					lastDay: '[' + this.labels.yesterday + ']',
					lastWeek: '[' + this.labels.last + '] dddd',
					sameElse: 'DD/MM/YYYY'
				} : null;
				return moment(this.row.record.dateValueDb).calendar(null, settings);
			} else {
				return moment(this.row.record.dateValueDb).format('L');
			}
		} catch (error) {
			return this.row.record.dateValueDb;
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