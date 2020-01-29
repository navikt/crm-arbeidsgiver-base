import { LightningElement, track, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

import MOMENT_JS from '@salesforce/resourceUrl/moment_js';
import getTimelineItemData from '@salesforce/apex/TAG_ActivityTimelineDataProvider.getTimelineItemData';
import getTimelineObjects from '@salesforce/apex/TAG_ActivityTimelineDataProvider.getTimelineObjects';
import labels from "./labels";

export default class TagActivityTimeline extends LightningElement {

	// config settings
	@api headerIcon = 'custom:custom18';
	@api headerTitle = 'Aktiviteter';

	// controller variables
	@api recordId;
	@track overdue = 3;
	@track upcoming = 3;
	@track thisMonth = 3;
	@track previousMonth = 3;
	@track older = 3;
	@api amountOfRecords = [];

	@track data;
	@track sObjectKinds;

	@track error;
	@track errorMsg;
	@track loading = true;
	@track loadingStyle = 'height:5rem;width:24rem';

	@track activeSections = [labels.overdue, labels.upcoming];
	@track labels = labels;

	collapsed = false;
	@track collapseIcon = 'utility:justify_text';
	@track collapseText = labels.collapse;

	connectedCallback() {

		this.amountOfRecords = [
			{ id: this.labels.overdue, amount: this.overdue },
			{ id: this.labels.upcoming, amount: this.upcoming },
			{ id: this.labels.thisMonth, amount: this.thisMonth },
			{ id: this.labels.previousMonth, amount: this.previousMonth },
			{ id: this.labels.older, amount: this.older }];

		Promise.all([
			loadScript(this, MOMENT_JS),
		]).then(() => {
			moment.locale(this.labels.MomentJsLanguage);
		});

		getTimelineObjects({ recordId: this.recordId }).then(data => { this.sObjectKinds = data; }).catch(error => { // todo move somewhere without mulitple calls
			this.error = true;
			if (error.body && error.body.exceptionType && error.body.message) {
				this.errorMsg = `[ ${error.body.exceptionType} ] : ${error.body.message}`;
			} else {
				this.errorMsg = JSON.stringify(error);
			}
		});

		if (this.headerIcon !== undefined) {
			this.showHeader = true;
		}
	}

	// todo oppdater til å ta inn amount pthis.er periode
	@wire(getTimelineItemData, { recordId: '$recordId', amountOfRecords: '$amountOfRecords' })
	deWire({ error, data }) {
		if (data) {
			this.data = data;
			this.loading = false;
			this.loadingStyle = '';
		} else if (error) {
			this.error = true;
			this.loading = false;
			this.errorMsg = error;
		}
	}

	loadMore(event) {

		var groupId = event.target.dataset.id;

		if (groupId === this.labels.overdue) {
			this.overdue += 5;
		} else if (groupId === this.labels.upcoming) {
			this.upcoming += 5;
		} else if (groupId === this.labels.thisMonth) {
			this.thisMonth += 5;
		} else if (groupId === this.labels.previousMonth) {
			this.previousMonth += 5;
		} else if (groupId === this.labels.older) {
			this.older += 5;
		}
		this.amountOfRecords = [
			{ id: this.labels.overdue, amount: this.overdue },
			{ id: this.labels.upcoming, amount: this.upcoming },
			{ id: this.labels.thisMonth, amount: this.thisMonth },
			{ id: this.labels.previousMonth, amount: this.previousMonth },
			{ id: this.labels.older, amount: this.older }];

		this.loading = true;
	}

	collapseAccordions() {
		this.activeSections = this.collapsed ? [this.labels.overdue, this.labels.upcoming, this.labels.thisMonth, this.labels.previousMonth, this.labels.older] : [];
	}

	handleSectionToggle(event) {
		this.activeSections = event.detail.openSections;
		console.log('this.labels.collapse: ' + this.labels.collapse);
		console.log('this.labels.expand: ' + this.labels.expand);
		if (this.activeSections.length === 0) {
			this.collapseIcon = 'utility:snippet';
			this.collapseText = this.labels.expand;
			this.collapsed = true;
		} else {
			this.collapseIcon = 'utility:justify_text';
			this.collapseText = this.labels.collapse;
			this.collapsed = false;
		}
	}
}