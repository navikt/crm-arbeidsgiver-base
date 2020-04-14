import { LightningElement, wire, api, track } from 'lwc';
import getdata from "@salesforce/apex/ArbeidsplassenController.getData";
import * as helper from "./helper";
import columns from "./columns";


export default class ArbeidsplassenView extends LightningElement {

	@api recordId;

	// fetch data
	wiredData;
	@track amount;
	@track data;
	@track columns = columns.columns;

	// for sorting
	@track sortBy;
	@track sortDirection;


	@wire(getdata, { recordId: '$recordId' })
	deWire(result) {
		this.wiredData = result;
		if (result.data) {
			this.amount = result.data.amount;
			this.data = result.data.models;
		} else if (result.error) {
			// this.setError(result.error);
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

}