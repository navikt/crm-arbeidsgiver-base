import { LightningElement, wire, api, track } from 'lwc';
import getdata from "@salesforce/apex/ArbeidsplassenController.getData";
import * as helper from "./helper";
import columns from "./columns";


export default class ArbeidsplassenView extends LightningElement {

	@api recordId;

	// fetch data
	wiredData;
	@track amount = 0;
	@track data;
	@track columns = columns.columns;
	@track showData = false;

	// error
	@track isError = false;
	@track errorMsg;

	// empty
	@track isEmpty = false;

	// loading
	@track isLoading = true;


	// for sorting
	@track sortBy;
	@track sortDirection;


	@wire(getdata, { recordId: '$recordId' })
	deWire(result) {
		this.wiredData = result;
		if (result.data) {

			this.isEmpty = result.data.amount == 0;
			this.showData = result.data.amount > 0;

			this.amount = result.data.amount;
			this.data = result.data.models;
			this.isLoading = false;

		} else if (result.error) {
			this.setError(result.error);
			this.isLoading = false;
		}
	}

	updateColumnSorting(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		this.data = helper.sortData(this.data, this.sortBy, this.sortDirection);
	}

	handleRowAction(event) {
		const action = event.detail.action;
		const row = event.detail.row;

		switch (action.name) {

			case "openUrl":
				window.open(row.link, "_blank");
				break;
			default:
				break;
		}
	}

	setError(error) {
		this.isError = true;
		if (error.body && error.body.message) {
			this.errorMsg = `${error.body.message}`;
		} else if (typeof error === String) {
			this.errorMsg = error;
		} else {
			this.errorMsg = JSON.stringify(error);
		}
	}

}