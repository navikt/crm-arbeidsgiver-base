import { LightningElement, api, wire, track } from 'lwc';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Id from '@salesforce/user/Id';
import deleteTeamMember from '@salesforce/apex/accountTeamMemberController.deleteTeamMember';
import getData from '@salesforce/apex/accountTeamMemberController.getData';

const actions = [
    { label: 'Rediger', name: 'edit' },
    { label: 'Slett', name: 'delete' }
];

const columns = [
    { label: 'Navn', fieldName: 'UserId' },
    { label: 'Rolle', fieldName: 'TeamMemberRole' },
    { label: 'Tema', fieldName: 'Departments' },
    { label: 'Nav-kontor', fieldName: 'CompanyName' },
    { label: 'Telefon', fieldName: 'MobilePhone', type: 'phone' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];

export default class AccountTeamMember extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track amount = 0;
    @track columns = columns;
    @track showData = false;
    @track isModalOpen = false;
    @track currentRowId;
    @track currentRowUserId;

    refreshTable;
    error;
    userId = Id;

    
    @wire(getData, { recordId: '$recordId' })
    member(result) {    
        console.log(JSON.stringify(result));    
        this.refreshTable = result;
        if (result.data) {
            this.data = result.data;
            this.amount = result.data.length;
            this.showData = result.data.length > 0;

            let dataList = [];
            this.data.forEach((element) => {
                let dataElement = {};
                dataElement.Id = element.Id;
                dataElement.UserId = element.User.Name;
                dataElement.TeamMemberRole = element.TeamMemberRole;
                dataElement.Departments = element.Departments__c;
                dataElement.CompanyName = element.User.CompanyName;
                dataElement.MobilePhone = element.User.MobilePhone;
                dataList.push(dataElement);
            });

            this.data = dataList;
        } else{
            /*
            let mockresult = [
                {
                    Id: '0011t00000XXXXXX',
                    AccountId: '0011t00000YYYYYY',
                    TeamMemberRole: 'Manager',
                    Departments__c: 'Sales',
                    User: {
                        Name: 'John Doe',
                        CompanyName: 'Acme Corporation',
                        MobilePhone: '123-456-7890'
                    }
                },
                {
                    Id: '0011t00000ZZZZZZ',
                    AccountId: '0011t00000YYYYYY',
                    TeamMemberRole: 'Developer',
                    Departments__c: 'Engineering',
                    User: {
                        Name: 'Jane Smith',
                        CompanyName: 'Tech Solutions',
                        MobilePhone: '987-654-3210'
                    }
                }
            ]; 
            this.data = mockresult;
            this.amount = mockresult.length;
            this.showData = mockresult.length > 0;
            let dataList = [];
            this.data.forEach((element) => {
                let dataElement = {};
                dataElement.Id = element.Id;
                dataElement.UserId = element.User.Name;
                dataElement.TeamMemberRole = element.TeamMemberRole;
                dataElement.Departments = element.Departments__c;
                dataElement.CompanyName = element.User.CompanyName;
                dataElement.MobilePhone = element.User.MobilePhone;
                dataList.push(dataElement);
            });
*/
           // this.data = dataList;
        }
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.currentRowId = row.Id;
        this.currentRowUserId = row.UserId;

        switch (actionName) {
            case 'delete':
                this.isModalOpen = true;
                break;
            case 'edit':
                this.editRow(row);
                break;
            default:
                break;
        }
    }

    deleteRow() {
        this.isModalOpen = false;
        deleteTeamMember({ atmId: this.currentRowId })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Kontaktperson ' + this.currentRowUserId + ' slettet ',
                        variant: 'success'
                    })
                );

                return refreshApex(this.refreshTable);
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Feil',
                        message: error.message,
                        variant: 'error'
                    })
                );
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
                },
                state: {
                    navigationLocation: 'RELATED_LIST',
                    defaultFieldValues: defaultValues
                }
            });
        }

    navigateToRelatedRecordsPage() {
        
        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
              componentName: "c__responsiveDataTable",
            },
            state: {
                c__p1: this.recordId,
            },
          });
    }
    
    refreshData() {
        return refreshApex(this.refreshTable);
    }
    closeModal() {
        this.isModalOpen = false;
    }

    get isDesktop() {
        console.log(FORM_FACTOR);
        return FORM_FACTOR === 'Large' ? true : false;
    }
}
