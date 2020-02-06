import { LightningElement, track, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import LANG from '@salesforce/i18n/lang';

import MOMENT_JS from '@salesforce/resourceUrl/moment_js';
import getTimelineItemData from '@salesforce/apex/TAG_ActivityTimelineController.getTimelineItemData';
import getTimelineObjects from '@salesforce/apex/TAG_ActivityTimelineController.getTimelineObjects';
import labels from "./labels";

export default class TagActivityTimeline extends LightningElement {

	// config settings
	@api headerIcon = 'custom:custom18';
	@api headerTitleNorwegian;
	@api headerTitleEnglish;

	@track header;

	// controller variables
	@api recordId;
	@track overdue = 3;
	@track upcoming = 3; // TODO remove track
	@track thisMonth = 3;
	@track previousMonth = 3;
	@track older = 3;
	@api amountOfRecords = [];

	@track previousOverdue;
	@track previousUpcoming;
	@track previousThisMonth;
	@track previousPreviousMonth;
	@track previousOlder;

	@track loadedAllOverdue = false;
	@track loadedAllUpcoming = false;
	@track loadedAllThisMonth = false;
	@track loadedAllPreviousMonth = false;
	@track loadedAllOlder = false;

	@track data;
	deWireResult;
	@track sObjectKinds;

	@track error = false;
	@track errorMsg;
	@track empty = false;

	@track loading = true;
	@track loadingStyle = 'height:5rem;width:24rem';

	@track activeSections = [labels.overdue, labels.upcoming];
	@track labels = labels;

	collapsed = false;
	@track collapseIcon = 'utility:justify_text';
	@track collapseText = labels.collapse;

	connectedCallback() {

		this.amountOfRecords = [
			{ id: this.labels.overdue, amount: this.overdue, loadedAll: this.loadedAllOverdue },
			{ id: this.labels.upcoming, amount: this.upcoming, loadedAll: this.loadedAllUpcoming },
			{ id: this.labels.thisMonth, amount: this.thisMonth, loadedAll: this.loadedAllThisMonth },
			{ id: this.labels.previousMonth, amount: this.previousMonth, loadedAll: this.loadedAllPreviousMonth },
			{ id: this.labels.older, amount: this.older, loadedAll: this.loadedAllOlder }];

		Promise.all([
			loadScript(this, MOMENT_JS),
		]).then(() => {
			moment.locale(this.labels.MomentJsLanguage);
		});

		getTimelineObjects({ recordId: this.recordId }).then(data => { this.sObjectKinds = data; }).catch(error => {
			this.error = true;
			this.setError();
		});

		if (LANG === 'no' && this.headerTitleNorwegian !== undefined) {
			this.header = this.headerTitleNorwegian;
		} else if (LANG === 'en-US' && this.headerTitleEnglish !== undefined) {
			this.header = this.headerTitleEnglish;
		} else {
			this.header = this.labels.activities;
		}
	}

	renderedCallback() {


	}

	@wire(getTimelineItemData, { recordId: '$recordId', amountOfRecords: '$amountOfRecords' })
	deWire(result) {
		this.deWireResult = result;
		if (result.data) {
			this.data = result.data;
			this.loading = false;
			this.loadingStyle = '';
			if (result.data.length === 0) {
				this.empty = true;
			} else {
				this.empty = false;

				for (let i = 0; i < this.data.length; i++) {
					const elem = result.data[i];
					var groupId = elem.id;
					var amount = elem.models.length;
					var loadedAll = elem.allObjectsLoaded;

					if (groupId === this.labels.overdue) {
						this.previousOverdue = amount;
						this.loadedAllOverdue = loadedAll;
					} else if (groupId === this.labels.upcoming) {
						this.previousUpcoming = amount;
						this.loadedAllUpcoming = loadedAll;
					} else if (groupId === this.labels.thisMonth) {
						this.previousThisMonth = amount;
						this.loadedAllThisMonth = loadedAll;
					} else if (groupId === this.labels.previousMonth) {
						this.previousPreviousMonth = amount;
						this.loadedAllPreviousMonth = loadedAll;
					} else if (groupId === this.labels.older) {
						this.previousOlder = amount;
						this.loadedAllOlder = loadedAll;
					}
				}
			}
		} else if (result.error) {
			this.error = true;
			this.loading = false;
			this.setError(result.error);
		}
	}

	setError(error) {
		if (error.body && error.body.exceptionType && error.body.message) {
			this.errorMsg = `[ ${error.body.exceptionType} ] : ${error.body.message}`;
		} else if (error.body && error.body.message) {
			this.errorMsg = `${error.body.message}`;
		} else if (typeof error === String) {
			this.errorMsg = error;
		} else {
			this.errorMsg = JSON.stringify(error);
		}
	}

	refreshData() {
		this.error = false;
		this.loading = true;
		return refreshApex(this.deWireResult);
	}

	loadMore(event) {

		var groupId = event.target.dataset.id;

		if (groupId === this.labels.overdue) { this.overdue += 3; }
		else if (groupId === this.labels.upcoming) { this.upcoming += 3; }
		else if (groupId === this.labels.thisMonth) { this.thisMonth += 3; }
		else if (groupId === this.labels.previousMonth) { this.previousMonth += 3; }
		else if (groupId === this.labels.older) { this.older += 3; }


		this.amountOfRecords = [
			{ id: this.labels.overdue, amount: this.overdue, previousAmount: this.previousOverdue, loadedAll: this.loadedAllOverdue, idUpdated: groupId },
			{ id: this.labels.upcoming, amount: this.upcoming, previousAmount: this.previousUpcoming, loadedAll: this.loadedAllUpcoming, idUpdated: groupId },
			{ id: this.labels.thisMonth, amount: this.thisMonth, previousAmount: this.previousThisMonth, loadedAll: this.loadedAllThisMonth, idUpdated: groupId },
			{ id: this.labels.previousMonth, amount: this.previousMonth, previousAmount: this.previousPreviousMonth, loadedAll: this.loadedAllPreviousMonth, idUpdated: groupId },
			{ id: this.labels.older, amount: this.older, previousAmount: this.previousOlder, loadedAll: this.loadedAllOlder, idUpdated: groupId }];

		this.loading = true;
	}

	collapseAccordions() {
		this.activeSections = this.collapsed ? [this.labels.overdue, this.labels.upcoming, this.labels.thisMonth, this.labels.previousMonth, this.labels.older] : [];
	}

	handleSectionToggle(event) {

		this.activeSections = event.detail.openSections;

		if (this.activeSections.length === 0) {
			this.collapseIcon = 'utility:filter';
			this.collapseText = this.labels.expand;
			this.collapsed = true;
		} else {
			this.collapseIcon = 'utility:justify_text';
			this.collapseText = this.labels.collapse;
			this.collapsed = false;
		}
	}
}