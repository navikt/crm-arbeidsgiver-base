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
	@track childRecords;
	@track error;
	@track data;
	@track errorMsg;
	@track momentJSLoaded = false;


	connectedCallback() {
		Promise.all([
			loadScript(this, MOMENT_JS),
		]).then(() => {
			this.momentJSLoaded = true;
			moment.locale('no');

			getTimelineItemData({ recordId: this.recordId })
				.then(data => {

					this.data = data;
					this.childRecords = new Array();
					let unsortedRecords = new Array();

					for (let j = 0; j < data.length; j++) {
						let childRec = {};
						childRec.isTask = false;
						childRec.isCustom = true;
						childRec.object = "Task";
						childRec.title = data[j]['Subject'];
						childRec.dateValueDB = data[j]['ActivityDate'];
						childRec.dateValue = moment(childRec.dateValueDB).fromNow();
						childRec.recordId = data[j].Id;
						unsortedRecords.push(childRec);
					}
					unsortedRecords.sort(function (a, b) {
						return new Date(b.dateValueDB) - new Date(a.dateValueDB);
					});
					this.childRecords = unsortedRecords;
					console.log('this.childRecords: ' + this.childRecords);
				}).catch(error => {
					this.error = true;
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