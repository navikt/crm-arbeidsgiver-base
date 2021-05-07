import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getData from '@salesforce/apex/CampaignMemberController.getData';
import deleteCampaignMember from '@salesforce/apex/CampaignMemberController.deleteCampaignMember';

const actions = [
    { label: 'Rediger', name: 'edit' },
    { label: 'Slett', name: 'delete' },
];

const columns = [
    { label: 'Name', fieldName: 'recordLink', type: 'url', wrapText: false, 
    typeAttributes: { label: { fieldName: "Name" }, target: "_self" }  },
    { label: 'Konto', fieldName: 'accountLink', type: 'url', wrapText: false,
    typeAttributes: { label: { fieldName: "Account" }, target: "_self" }  },
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];
export default class CampaignMembers extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track amount = 0;
    @track columns = columns;
    @track showData = false;
    @track isModalOpen = false;

    @wire(getData, { recordId: '$recordId' })
    member(result) {
        this.refreshTable = result;
        if (result.data) {
            this.data = result.data;
            this.amount = result.data.length;
            this.showData = result.data.length > 0;
            console.log('yo', result.data);

            let dataList = [];
            this.data.forEach((element) => {
                let dataElement = {};
                dataElement.Id = element.Id;
                dataElement.Name = element.Name;
                dataElement.Account = element.Account__r.Name;
                dataElement.recordLink = "/" + element.Id; 
                dataElement.accountLink = "/" + element.Account__c;
                dataList.push(dataElement);
            });

            this.data = dataList;
        }
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.currentRowId = row.Id;
        this.currentRowUserId = row.UserId;
        
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

    editRow(currentRow) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: currentRow.Id,
                objectApiName: 'CustomCampaignMember__c',
                actionName: 'edit'
            }
        });
    }

    deleteRow(currentRow) {
        deleteCampaignMember({ recordId: this.currentRowId })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Bedriftskampanjemedlem slettet ',
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

    navigateToNewRecordPage() {
       const defaultValues = encodeDefaultFieldValues({
            CustomCampaign__c: this.recordId
           // UserId: this.userId
        }); 
        console.log('1');
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'CustomCampaignMember__c',
                actionName: 'new'
            },
            state: {
                navigationLocation: 'RELATED_LIST',
                defaultFieldValues: defaultValues
            }
        });
    }
}
