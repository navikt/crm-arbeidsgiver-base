import { LightningElement, track, api } from 'lwc';
import getTimelineItemData from '@salesforce/apex/TAG_ActivityTimelineDataProvider.getTimelineItemData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import MOMENT_JS from '@salesforce/resourceUrl/moment_js';
import CURRENT_USER_ID from '@salesforce/user/Id';

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

	connectedCallback() {
		Promise.all([
			loadScript(this, MOMENT_JS),
		]).then(() => {
			this.momentJSLoaded = true;
			moment.locale('no');

			getTimelineItemData({ recordId: this.recordId })
				.then(data => {

					this.data = new Array();
					let unsortedRecords = new Array();

					for (let j = 0; j < data.length; j++) {

						let conf = data[j].config;
						let sObj = data[j].sObj;
						let childRec = {};

						childRec.object = conf['SObjectChild__c'];
						childRec.title = sObj[conf['SObjectTitle__c']];
						childRec.dateValueDB = sObj[conf['SObjectDateField__c']];
						childRec.recordId = sObj.Id;
						childRec.themeInfo = {
							icon: conf['Icon__c'],
							sldsTimelineItem: conf['SLDS_Timeline_Item__c']
						};

						if (childRec.object === 'Task') {

							childRec.type = sObj['Type'];

							if (childRec.type === 'Call') {
								childRec.themeInfo.icon = 'standard:log_a_call';
								childRec.themeInfo.sldsTimelineItem = 'slds-timeline__item_call';
							}
						}

						childRec.dateValue = moment(childRec.dateValueDB).fromNow();
						unsortedRecords.push(childRec);
					}
					unsortedRecords.sort(function (a, b) {
						return new Date(b.dateValueDB) - new Date(a.dateValueDB);
					});

					let upcoming = new Array();
					let thisMonth = new Array();
					let previousMonth = new Array();
					let older = new Array();

					for (let i = 0; i < unsortedRecords.length; i++) {

						const element = unsortedRecords[i];

						let recordDate = new Date(element.dateValueDB);
						let now = new Date();
						let tmp = new Date();
						let oneMonth = tmp.setMonth(now.getMonth() - 1);


						if (recordDate >= now) {
							upcoming.push(element);
						} else if (recordDate < now && recordDate.getMonth() == now.getMonth()) {
							thisMonth.push(element);
						} else if (recordDate < now && recordDate.getMonth() == now.getMonth() + 1) {
							previousMonth.push(element);
						} else {
							older.push(element);
						}
					}

					// this.data = unsortedRecords;
					if (upcoming.length > 0) {
						this.data.push({ name: 'Upcoming & Overdue', id: 'upcoming', data: upcoming });
						this.activeSections.push('upcoming');
					}
					if (thisMonth.length > 0) {
						this.data.push({ name: 'This Month', id: 'thisMonth', data: thisMonth });
						// this.activeSections.push('thisMonth');
					}
					if (previousMonth.length > 0) {
						this.data.push({ name: 'Previous Month', id: 'previousMonth', data: previousMonth });
						// this.activeSections.push('previousMonth');
					}
					if (older.length > 0) {
						this.data.push({ name: 'Older', id: 'older', data: older });
						// this.activeSections.push('older');
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