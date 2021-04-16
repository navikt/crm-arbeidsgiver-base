import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/CampaignMemberController.getData';

const actions = [
    { label: 'Rediger', name: 'edit' },
    { label: 'Slett', name: 'delete' }
];

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Konto', fieldName: 'Account__c' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];
export default class CampaignMembers extends LightningElement {
    @api recordId;
    @track data;
    @track amount = 0;
    @track columns = columns;
    @track showData = false;

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
                dataElement.Account = element.Account__c;
                dataList.push(dataElement);
            });

            this.data = dataList;
        }
    }
}
