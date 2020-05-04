import { LightningElement, api, wire, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

import getData from '@salesforce/apex/AccountTeamMemberController.getData';
import deleteTeamMember from '@salesforce/apex/AccountTeamMemberController.deleteTeamMember';
import addTeamMember from '@salesforce/apex/AccountTeamMemberController.addTeamMember';
import { refreshApex } from '@salesforce/apex';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';


const actions = [
	{ label: 'Edit', name: 'edit' },
	{ label: 'Delete', name: 'delete' },
];

const columns = [
	{ label: 'Navn', fieldName: 'UserId' },
	{ label: 'Rolle', fieldName: 'TeamMemberRole' },
	{
		type: 'action',
		typeAttributes: { rowActions: actions },
	},
];

export default class AccountTeamMember extends NavigationMixin(LightningElement) {
	@api recordId;
	@track data;
	@track columns = columns;
	@track showModal = false;

	refreshTable;
	error;
	userId = Id;



	@wire(getData, { recordId: '$recordId' })
	member(result) {

		if (result.data) {
			this.refreshTable = result;
			this.data = result.data;

			let dataList = [];
			this.data.forEach(element => {
				let dataElement = {};
				dataElement.Id = element.Id;
				dataElement.UserId = element.User.Name;
				dataElement.TeamMemberRole = element.TeamMemberRole;
				dataList.push(dataElement);
			});

			this.data = dataList;
		}
	}



	handleRowActions(event) {
		let actionName = event.detail.action.name;
		let row = event.detail.row;

		switch (actionName) {
			case 'edit':
				this.editCurrentRecord(row);
				break;
			case 'delete':
				this.deleteRow(row);
				break;
		}
	}

	deleteRow(currentRow) {
		deleteTeamMember({ atmId: currentRow.Id })
			.then(result => {
				this.dispatchEvent(new ShowToastEvent({
					title: 'Success',
					message: 'Kontaktperson ' + currentRow.UserId + ' slettet ',
					variant: 'success'
				}));

				return refreshApex(this.refreshTable);

			})
			.catch(error => {
				window.console.log('Error ====> ' + error);
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error',
					message: error.message,
					variant: 'error'
				}));
			});
	}

	editCurrentRecord(currentRow) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.currentRow.Id,
				objectApiName: 'AccountTeamMember', // objectApiName is optional
				actionName: 'edit'
			}
		});
	}
	navigateToNewRecordPage() {
		const defaultValues = encodeDefaultFieldValues({
			AccountId: this.recordId,
			UserId: this.userId
		});
		this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: 'AccountTeamMember',
				actionName: 'new'
			}, state: {
				nooverride: '1',
				navigationLocation: 'LOOKUP',
				defaultFieldValues: defaultValues
			}
		});
		// refreshing table data using refresh apex
		return refreshApex(this.refreshTable);
	}
}