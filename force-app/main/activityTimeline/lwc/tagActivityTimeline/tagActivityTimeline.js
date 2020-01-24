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
	@track amountOverdue = 5;

	@track data;
	@track sObjectKinds;
	@track error;
	@track errorMsg;
	@track loading = true;
	@track momentJSLoaded = false;
	@track activeSections = [];
	@track labels = labels;

	connectedCallback() {

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

	renderedCallback() {
		this.loading = false; // todo fix loading icon
	}

	// todo oppdater til å ta inn amount per periode
	@wire(getTimelineItemData, { recordId: '$recordId' })
	deWire({ error, data }) {
		if (data) {
			this.data = data;
		} else if (error) {
			this.error = true;
			this.loading = false;
			this.errorMsg = error;
		}
	}

	loadMore(event) {
		console.log('load more');
	}
}