import { LightningElement, api, wire, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

import getData from '@salesforce/apex/accountTeamMemberController.getData';
import deleteTeamMember from '@salesforce/apex/accountTeamMemberController.deleteTeamMember';
import { refreshApex } from '@salesforce/apex';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';


const actions = [
    { label: 'Rediger', name: 'edit' },
    { label: 'Slett', name: 'delete' },
];

const columns = [
    { label: 'Navn', fieldName: 'UserId', initialWidth: 200 },
    { label: 'Rolle', fieldName: 'TeamMemberRole', initialWidth: 200 },
    { label: 'Område', fieldName: 'Departments' },
    { label: 'Telefon', fieldName: 'MobilePhone', initialWidth: 150 },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class AccountTeamMember extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track amount = 0;
    @track columns = columns;
    @track showData = false;

    refreshTable;
    error;
    userId = Id;


    @wire(getData, { recordId: '$recordId' })
    member(result) {
        this.refreshTable = result;
        if (result.data) {
            this.data = result.data;
            this.amount = result.data.length;
            this.showData = result.data.length > 0;

            let dataList = [];
            this.data.forEach(element => {
                let dataElement = {};
                dataElement.Id = element.Id;
                dataElement.UserId = element.User.Name;
                dataElement.TeamMemberRole = element.TeamMemberRole;
                dataElement.Departments = element.Departments__c;
                dataElement.MobilePhone = element.User.MobilePhone;
                dataList.push(dataElement);
            });

            this.data = dataList;
        }
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;

        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.editRow(row);
                break;
            default:
                break;
        }
    }

    deleteRow(currentRow) {
        deleteTeamMember({ atmId: currentRow.Id })
            .then(result => {
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Kontaktperson ' + currentRow.UserId + ' slettet ',
                    variant: 'success'
                }));

                return refreshApex(this.refreshTable);

            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Feil',
                    message: error.message,
                    variant: 'error'
                }));
            });
    }

    editRow(currentRow) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: currentRow.Id,
                objectApiName: 'AccountTeamMember',
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
                navigationLocation: 'RELATED_LIST',
                defaultFieldValues: defaultValues
            }
        });
    }
    refreshData() {
        return refreshApex(this.refreshTable);
    }
}