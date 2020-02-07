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
	@api recordId;

	@api amountOfMonths = 4;
	@api amountOfMonthsToLoad = 4;
	@api amountOfRecords = 3;
	@api amountOfRecordsToLoad = 3;

	@track data;
	deWireResult;
	@track sObjectKinds;

	@track header;
	@track error = false;
	@track errorMsg;
	@track empty = false;

	@track loading = true;
	@track loadingStyle = 'height:5rem;width:24rem';

	@track activeSections = [labels.overdue, labels.upcoming];
	allSections = [];
	@track labels = labels;

	collapsed = false;
	@track collapseIcon = 'utility:justify_text';
	@track collapseText = labels.collapse;

	connectedCallback() {

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

	@wire(getTimelineItemData, { recordId: '$recordId', amountOfMonths: '$amountOfMonths' })
	deWire(result) {
		this.deWireResult = result;

		if (result.data) {

			this.data = result.data;
			this.loading = false;
			this.loadingStyle = '';
			this.empty = result.data.length === 0;

			for (let i = 0; i < this.data.length; i++) {
				const elem = result.data[i];
				this.allSections.push(elem.id);
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
		this.loading = true;
		this.amountOfMonths += this.amountOfMonthsToLoad;
	}

	collapseAccordions() {
		this.activeSections = this.collapsed ? this.allSections : [];
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