import { LightningElement, track, api } from 'lwc';
import getTimelineItemData from '@salesforce/apex/TAG_ActivityTimelineDataProvider.getTimelineItemData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import MOMENT_JS from '@salesforce/resourceUrl/moment_js';
import CURRENT_USER_ID from '@salesforce/user/Id';
import labels from "./labels";

export default class TagActivityTimeline extends LightningElement {

	@api recordId;
	@api headerTitle;
	@api headerIcon;
	@api showHeader = false;
	@api additionalMargin;
	@track data;
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

			this.momentJSLoaded = true;
			moment.locale(labels.MomentJsLanguage);

		}).then(() => {

			getTimelineItemData({ recordId: this.recordId })
				.then(data => {

					this.data = new Array();
					let unsortedRecords = new Array();

					for (let j = 0; j < data.length; j++) {


						let row = data[j];
						row.record.dateValue = moment(row.record.dateValueDb).fromNow();
						unsortedRecords.push(row);
					}

					unsortedRecords.sort(function (a, b) {
						return new Date(b.record.dateValueDb) - new Date(a.record.dateValueDb);
					});

					let overdue = new Array();
					let upcoming = new Array();
					let thisMonth = new Array();
					let previousMonth = new Array();
					let older = new Array();

					let now = new Date();
					const monthNumber = now.getMonth();
					const previousMonthNumber = monthNumber == 0 ? 11 : monthNumber - 1;
					const nextMonthNumber = monthNumber == 11 ? 0 : monthNumber - 1;

					for (let i = 0; i < unsortedRecords.length; i++) {

						const element = unsortedRecords[i];
						const recordDate = new Date(element.record.dateValueDb);


						if (element.record.overdue) {
							overdue.push(element);
						} else if (recordDate >= now) {
							upcoming.push(element);
						} else if (recordDate < now && recordDate.getMonth() == monthNumber) {
							thisMonth.push(element);
						} else if (recordDate < now && recordDate.getMonth() == nextMonthNumber) {
							previousMonth.push(element);
						} else {
							older.push(element);
						}
					}

					const months = moment.months();

					const currentMonthName = months[monthNumber];
					const previousMonthName = months[previousMonthNumber];

					const currentMonthNameUpper = currentMonthName.charAt(0).toUpperCase() + currentMonthName.substring(1);
					const previousMonthNameUpper = previousMonthName.charAt(0).toUpperCase() + previousMonthName.substring(1);


					if (overdue.length > 0) {
						this.data.push({ name: labels.overdue, id: 'overdue', data: overdue.reverse() });
						this.activeSections.push('overdue');
					} if (upcoming.length > 0) {
						this.data.push({ name: labels.upcoming, id: 'upcoming', data: upcoming.reverse() });
						this.activeSections.push('upcoming');
					} if (thisMonth.length > 0) {
						this.data.push({ name: currentMonthNameUpper, id: 'thisMonth', data: thisMonth });
					} if (previousMonth.length > 0) {
						this.data.push({ name: previousMonthNameUpper, id: 'previousMonth', data: previousMonth });
					} if (older.length > 0) {
						this.data.push({ name: labels.older, id: 'older', data: older });
					}

					this.loading = false;

				}).catch(error => {
					this.error = true;
					this.loading = false;
					if (error.body && error.body.exceptionType && error.body.message) {
						this.errorMsg = `[ ${error.body.exceptionType} ] : ${error.body.message}`;
					} else {
						this.errorMsg = JSON.stringify(error);
					}
				});
		})
			.catch(error => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error loading MomentJS',
						message: error.message,
						variant: 'error',
					}),
				);
			});
	}


}